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
    stream_names = get_stream_names_map(stream_traces)

    # base_diff = TermDiffer.diff(%{}, base_stream_state)

    # {_, initial_term_tree} =
    #   TermParser.update_by_diff(
    #     TermParser.term_to_display_tree(%{}),
    #     base_diff
    #   )

    fun_list = collect_updates(stream_traces)
    # stream_names = Enum.map(stream_traces, &elem(&1, 0))

    # dbg({inserts, deletes})
    # deletes = ensure_delete_keys_present(inserts, deletes)

    # computed_lists = reconstruct_stream_lists(inserts, deletes)
    # # dbg(computed_lists)
    # stream_state = build_stream_state_map(computed_lists)
    # # dbg(stream_state)
    # final_diff = build_diff_from_computed_lists(computed_lists)
    # dbg(final_diff)

    {fun_list, stream_names}
  end

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

  defp get_stream_names_map(updates) do
    updates
    |> Enum.flat_map(fn update ->
      update
      |> Enum.filter(fn {_key, val} -> match?(%Phoenix.LiveView.LiveStream{}, val) end)
      |> Enum.map(fn {key, _} -> key end)
    end)
    |> Enum.uniq()
  end

  defp collect_updates(update_list) do
    update_list =
      update_list
      |> Enum.flat_map(&flatten_stream_updates(&1))

    dbg(update_list)
    update_list
  end

  def map_stream_entry_to_stream_function(%Phoenix.LiveView.LiveStream{
        name: name,
        inserts: inserts,
        deletes: deletes,
        reset?: reset?,
        consumable?: consumable?
      }) do
    []
    |> maybe_add_reset(reset?, name)
    |> maybe_add_inserts(inserts, name)
    |> maybe_add_deletes(deletes, name)
  end

  defp maybe_add_reset(functions, true, name) do
    functions ++ [fn socket -> Phoenix.LiveView.stream(socket, name, [], reset: true) end]
  end

  defp maybe_add_reset(functions, false, _name), do: functions

  defp maybe_add_inserts(functions, [], _name), do: functions

  defp maybe_add_inserts(functions, inserts, name) do
    functions ++ create_insert_functions(inserts, name)
  end

  defp maybe_add_deletes(functions, [], _name), do: functions

  defp maybe_add_deletes(functions, deletes, name) do
    functions ++ create_delete_functions(deletes, name)
  end

  defp create_insert_functions(inserts, name) do
    Enum.map(inserts, fn {dom_id, at, element, limit, update?} ->
      fn socket ->
        Phoenix.LiveView.stream_insert(socket, name, element,
          at: at,
          limit: limit,
          update: update?
        )
      end
    end)
  end

  defp create_delete_functions(deletes, name) do
    Enum.map(deletes, fn dom_id ->
      dbg(dom_id)

      fn socket ->
        Phoenix.LiveView.stream_delete_by_dom_id(socket, name, dom_id)
      end
    end)
  end

  defp flatten_stream_updates(stream_entry) do
    Enum.flat_map(stream_entry, fn
      {stream_name, %Phoenix.LiveView.LiveStream{} = stream} ->
        dbg(map_stream_entry_to_stream_function(stream))
        map_stream_entry_to_stream_function(stream)

      _ ->
        []
    end)
  end

  # defp reconstruct_stream_lists(inserts, deletes) do
  #   inserts
  #   |> Enum.map(fn {stream_name, stream_inserts} ->
  #     list = build_stream_list_from_inserts(stream_inserts)
  #     deleted_ids = Map.get(deletes, stream_name, [])
  #     # dbg(list)
  #     # dbg(deleted_ids)

  #     cleaned =
  #       Enum.reduce(deleted_ids, list, fn dom_id, acc ->
  #         List.keydelete(acc, dom_id, 0)
  #       end)

  #     {stream_name, cleaned}
  #   end)
  # end

  # defp build_stream_list_from_inserts(inserts) do
  #   Enum.reduce(Enum.reverse(inserts), [], fn {dom_id, _, element, _, updated?}, acc ->
  #     if updated? do
  #       List.keyreplace(acc, dom_id, 0, {dom_id, element})
  #     else
  #       List.insert_at(acc, 0, {dom_id, element})
  #     end
  #   end)
  # end

  # defp build_stream_state_map(list_map) do
  #   list_map
  #   |> Enum.map(fn {stream_name, list} ->
  #     stream_state =
  #       Enum.with_index(list, fn {dom_id, _val}, idx ->
  #         {dom_id, idx}
  #       end)

  #     {stream_name, stream_state}
  #   end)
  #   |> Map.new()
  # end

  # defp build_diff_from_computed_lists(list_map) do
  #   diff_map =
  #     Enum.reduce(list_map, %{}, fn {stream_name, list}, acc ->
  #       inserts =
  #         list
  #         |> Enum.with_index()
  #         |> Enum.into(%{}, fn {{_dom_id, val}, index} ->
  #           {index, val}
  #         end)

  #       # dbg(inserts)

  #       list_diff = %Diff{type: :list, ins: inserts, del: %{}, diff: %{}}
  #       Map.put(acc, stream_name, list_diff)
  #     end)

  #   Map.put(@empty_diff, :diff, diff_map)
  # end

  # defp compute_stream_diff_update(inserts, deletes, current_state) do
  #   deleted_ids = MapSet.new(deletes)

  #   cleaned_state =
  #     Enum.reject(current_state, fn {dom_id, _} -> dom_id in deleted_ids end)

  #   reindexed_state =
  #     cleaned_state
  #     |> Enum.with_index()
  #     |> Enum.map(fn {{dom_id, _}, idx} -> {dom_id, idx} end)

  #   deleted_map =
  #     deletes
  #     |> Enum.map(fn dom_id ->
  #       case List.keyfind(current_state, dom_id, 0) do
  #         {^dom_id, idx} -> {idx, :deleted}
  #         _ -> nil
  #       end
  #     end)
  #     |> Enum.reject(&is_nil/1)
  #     |> Enum.into(%{})

  #   {insert_ops, updated_del_map, updated_state} =
  #     Enum.reduce(inserts, {[], %{}, reindexed_state}, fn
  #       {dom_id, index, value, _, true}, {ins_acc, del_acc, state_acc} ->
  #         {_, original_index} = List.keyfind(current_state, dom_id, 0)

  #         updated_del =
  #           if original_index, do: Map.put(del_acc, original_index, :deleted), else: del_acc

  #         # tu cos nie dzila jeszcze i kolejnosc jeszce jak insertujemy pod ten sam domid bez update to tez update xd i
  #         #  insert at index jesli jest mniej elementow to na koniec(update)
  #         updated_ins = List.insert_at(ins_acc, index, {dom_id, value})
  #         new_state = List.keyreplace(state_acc, dom_id, 0, {dom_id, index})

  #         {updated_ins, updated_del, new_state}

  #       {dom_id, index, value, _, false}, {ins_acc, del_acc, state_acc} ->
  #         {
  #           List.insert_at(ins_acc, index, {dom_id, value}),
  #           del_acc,
  #           List.insert_at(state_acc, index, {dom_id, index})
  #         }
  #     end)

  #   # dbg(ins_map)

  #   final_state =
  #     updated_state
  #     |> Enum.with_index()
  #     |> Enum.map(fn {{dom_id, _}, idx} -> {dom_id, idx} end)

  #   # dbg({insert_ops, final_state})

  #   ins_map =
  #     insert_ops
  #     |> Enum.map(fn {dom_id, val} ->
  #       {Keyword.fetch!(final_state, dom_id), val}
  #     end)
  #     |> Map.new()

  #   # dbg(ins_map)

  #   %{
  #     ins: ins_map,
  #     del: Map.merge(deleted_map, updated_del_map),
  #     final_state: final_state
  #   }
  # end
end
