defmodule LiveDebugger.App.Debugger.NodeState.StreamUtils do
  @moduledoc """
  Utilities for extracting and computing Phoenix LiveView stream diffs and state
  from render traces.
  """

  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermDiffer.Diff
  alias LiveDebugger.App.Utils.TermParser

  @empty_diff %Diff{type: :map, ins: %{}, del: %{}, diff: %{}}

  @doc """
  Given a tuple of render traces, compute the base stream diff and stream state.
  """
  def build_initial_stream_diff({stream_updates, _trace}) do
    stream_traces = extract_stream_traces(stream_updates)
    base_stream_state = infer_base_stream_state(stream_traces)

    base_diff = TermDiffer.diff(%{}, base_stream_state)

    {_, initial_term_tree} =
      TermParser.update_by_diff(
        TermParser.term_to_display_tree(%{}),
        base_diff
      )

    {inserts, deletes} = collect_all_updates(stream_traces)

    # dbg({inserts, deletes})
    deletes = ensure_delete_keys_present(inserts, deletes)

    computed_lists = reconstruct_stream_lists(inserts, deletes)
    # dbg(computed_lists)
    stream_state = build_stream_state_map(computed_lists)
    # dbg(stream_state)
    final_diff = build_diff_from_computed_lists(computed_lists)
    # dbg(final_diff)

    {initial_term_tree, final_diff, Map.to_list(stream_state)}
  end

  @doc """
  Computes the stream diff between updates and the current stream state.
  """
  def compute_diff(stream_updates, current_stream_state) do
    # dbg(stream_updates)
    # dbg(current_stream_state)

    inserts = collect_updates_by_type(stream_updates, :inserts)
    deletes = collect_updates_by_type(stream_updates, :deletes)

    # ddac porowananie dla wszystkich czy jakis nowy nie doszedl
    current_stream_state =
      if current_stream_state == [] do
        infer_initial_state_from_updates(stream_updates)
      else
        current_stream_state
      end

    {reset_map, new_state} =
      Enum.reduce(stream_updates, {%{}, current_stream_state}, fn
        %{items: %Phoenix.LiveView.LiveStream{} = stream} = update, {reset_acc, state_acc} ->
          Enum.reduce(Map.to_list(update), {reset_acc, state_acc}, fn
            {name, %Phoenix.LiveView.LiveStream{reset?: true}}, {reset_map, current_state} ->
              existing = Map.get(current_state, name, [])

              deleted_map =
                existing
                |> Enum.map(fn {id, _idx} -> {id, :deleted} end)
                |> Enum.into(%{})

              {
                Map.put(reset_map, name, deleted_map),
                Map.put(current_state, name, [])
              }

            {_name, %Phoenix.LiveView.LiveStream{}}, acc ->
              acc

            _, acc ->
              acc
          end)
      end)

    # deleted_map =
    #   reset_map
    #   |> Enum.map(fn dom_id ->
    #       {^dom_id, idx} -> {idx, :deleted}
    #       _ -> nil
    #     end
    #   end)
    #   |> Enum.reject(&is_nil/1)
    #   |> Enum.into(%{})

    # dbg({reset_map, new_state})

    {diffs, new_stream_state} =
      Enum.reduce(current_stream_state, {%{}, %{}}, fn {stream_name, current_items},
                                                       {diff_acc, state_acc} ->
        update =
          compute_stream_diff_update(
            Map.get(inserts, stream_name, []),
            Map.get(deletes, stream_name, []),
            current_items
          )

        # dbg(update)

        diff_entry = %Diff{type: :list, ins: update.ins, del: update.del, diff: %{}}

        {
          Map.put(diff_acc, stream_name, diff_entry),
          Map.put(state_acc, stream_name, update.final_state)
        }
      end)

    final_diff = Map.put(@empty_diff, :diff, diffs)
    # dbg(final_diff)
    # dbg(new_stream_state)

    {final_diff, new_stream_state}
  end

  @doc """
  Aggregates all stream inserts and deletes from a list of stream traces.
  """
  defp collect_all_updates(stream_traces) do
    inserts = collect_updates_by_type(stream_traces, :inserts)
    deletes = collect_updates_by_type(stream_traces, :deletes)
    {inserts, deletes}
  end

  # Internal helpers

  defp extract_stream_traces(stream_updates) do
    stream_updates
    |> Enum.sort_by(& &1.timestamp, :asc)
    |> Enum.flat_map(& &1.args)
    |> Enum.map(&Map.get(&1, :streams, []))
    |> Enum.reject(&Enum.empty?/1)
  end

  defp infer_base_stream_state([]), do: %{}

  defp infer_base_stream_state([first_trace | _]) do
    first_trace
    |> Enum.filter(fn {_, val} -> match?(%Phoenix.LiveView.LiveStream{}, val) end)
    |> Map.new(fn {key, _val} -> {key, []} end)
  end

  defp infer_initial_state_from_updates(updates) do
    updates
    |> Enum.flat_map(fn update ->
      update
      |> Enum.filter(fn {_key, val} -> match?(%Phoenix.LiveView.LiveStream{}, val) end)
      |> Enum.map(fn {key, _} -> {key, []} end)
    end)
    |> Map.new()
  end

  defp ensure_delete_keys_present(inserts, deletes) do
    Enum.reduce(Map.keys(inserts), deletes, fn stream_name, acc ->
      Map.put_new(acc, stream_name, [])
    end)
  end

  defp collect_updates_by_type(update_list, type)
       when type in [:inserts, :deletes] do
    update_list
    |> Enum.flat_map(&flatten_stream_updates(&1, type))
    |> Enum.reduce(%{}, fn {stream_name, updates, reset?}, acc ->
      # dbg({stream_name, updates, reset?, acc})

      case reset? do
        true ->
          new_value = add_updates_to_stream([], updates)
          Map.put(acc, stream_name, new_value)


        false ->
          old_value = Map.get(acc, stream_name, [])
          new_value = add_updates_to_stream(old_value, updates)
          Map.put(acc, stream_name, new_value)
      end
    end)
  end

  defp add_updates_to_stream(current_state, updates) do
    # dbg({current_state, updates})

    result =
      Enum.reduce(Enum.reverse(updates), current_state, fn
        dom_id, acc when is_binary(dom_id) ->
          List.insert_at(acc, -1, String.to_atom(dom_id))

        {dom_id, at, element, limit, update?}, acc ->
          List.insert_at(acc, at, {String.to_atom(dom_id), at, element, limit, update?})
      end)

    # dbg(result)
    result
  end

  defp flatten_stream_updates(stream_entry, type) do
    Enum.flat_map(stream_entry, fn
      {stream_name, %Phoenix.LiveView.LiveStream{} = stream} ->
        updates =
          case type do
            :inserts -> stream.inserts
            :deletes -> stream.deletes
          end

        reset? = stream.reset?

        if updates != [] or reset? do
          [{stream_name, updates, reset?}]
        else
          []
        end

      _ ->
        []
    end)
  end

  defp reconstruct_stream_lists(inserts, deletes) do
    inserts
    |> Enum.map(fn {stream_name, stream_inserts} ->
      list = build_stream_list_from_inserts(stream_inserts)
      deleted_ids = Map.get(deletes, stream_name, [])
      # dbg(list)
      # dbg(deleted_ids)

      cleaned =
        Enum.reduce(deleted_ids, list, fn dom_id, acc ->
          List.keydelete(acc, dom_id, 0)
        end)

      {stream_name, cleaned}
    end)
  end

  defp build_stream_list_from_inserts(inserts) do
    Enum.reduce(Enum.reverse(inserts), [], fn {dom_id, _, element, _, updated?}, acc ->
      if updated? do
        List.keyreplace(acc, dom_id, 0, {dom_id, element})
      else
        List.insert_at(acc, 0, {dom_id, element})
      end
    end)
  end

  defp build_stream_state_map(list_map) do
    list_map
    |> Enum.map(fn {stream_name, list} ->
      stream_state =
        Enum.with_index(list, fn {dom_id, _val}, idx ->
          {dom_id, idx}
        end)

      {stream_name, stream_state}
    end)
    |> Map.new()
  end

  defp build_diff_from_computed_lists(list_map) do
    diff_map =
      Enum.reduce(list_map, %{}, fn {stream_name, list}, acc ->
        inserts =
          list
          |> Enum.with_index()
          |> Enum.into(%{}, fn {{_dom_id, val}, index} ->
            {index, val}
          end)

        # dbg(inserts)

        list_diff = %Diff{type: :list, ins: inserts, del: %{}, diff: %{}}
        Map.put(acc, stream_name, list_diff)
      end)

    Map.put(@empty_diff, :diff, diff_map)
  end

  defp compute_stream_diff_update(inserts, deletes, current_state) do
    deleted_ids = MapSet.new(deletes)

    cleaned_state =
      Enum.reject(current_state, fn {dom_id, _} -> dom_id in deleted_ids end)

    reindexed_state =
      cleaned_state
      |> Enum.with_index()
      |> Enum.map(fn {{dom_id, _}, idx} -> {dom_id, idx} end)

    deleted_map =
      deletes
      |> Enum.map(fn dom_id ->
        case List.keyfind(current_state, dom_id, 0) do
          {^dom_id, idx} -> {idx, :deleted}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{})

    {insert_ops, updated_del_map, updated_state} =
      Enum.reduce(inserts, {[], %{}, reindexed_state}, fn
        {dom_id, index, value, _, true}, {ins_acc, del_acc, state_acc} ->
          {_, original_index} = List.keyfind(current_state, dom_id, 0)

          updated_del =
            if original_index, do: Map.put(del_acc, original_index, :deleted), else: del_acc


          updated_ins = List.insert_at(ins_acc, index, {dom_id, value})
          new_state = List.keyreplace(state_acc, dom_id, 0, {dom_id, index})

          {updated_ins, updated_del, new_state}

        {dom_id, index, value, _, false}, {ins_acc, del_acc, state_acc} ->
          {
            List.insert_at(ins_acc, index, {dom_id, value}),
            del_acc,
            List.insert_at(state_acc, index, {dom_id, index})
          }
      end)

    # dbg(ins_map)

    final_state =
      updated_state
      |> Enum.with_index()
      |> Enum.map(fn {{dom_id, _}, idx} -> {dom_id, idx} end)

    # dbg({insert_ops, final_state})

    ins_map =
      insert_ops
      |> Enum.map(fn {dom_id, val} ->
        {Keyword.fetch!(final_state, dom_id), val}
      end)
      |> Map.new()

    # dbg(ins_map)

    %{
      ins: ins_map,
      del: Map.merge(deleted_map, updated_del_map),
      final_state: final_state
    }
  end
end
