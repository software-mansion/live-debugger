defmodule LiveDebugger.App.Debugger.NodeState.StreamUtils do
  @moduledoc """
  Utility functions for handling Phoenix LiveView stream updates and extracting stream state from render traces.
  """
  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermDiffer.Diff
  alias LiveDebugger.App.Utils.TermParser

  @empty_diff %Diff{
    type: :map,
    ins: %{},
    del: %{},
    diff: %{}
  }

  def calculate_initial_diff({stream_updates, _}) do
    streams_data =
      stream_updates
      |> Enum.sort_by(& &1.timestamp, :desc)
      |> Enum.flat_map(& &1.args)
      |> Enum.map(&Map.get(&1, :streams, []))
      |> Enum.reject(&Enum.empty?/1)

    initial_state = initialize_stream_state(streams_data)
    initial_diff = TermDiffer.diff(%{}, initial_state)

    {_, initial_term} =
      TermParser.update_by_diff(TermParser.term_to_display_tree(%{}), initial_diff)

    {inserts, deletes} = apply_stream_updates(streams_data, initial_state)

    deletes = maybe_fill_deletes(inserts, deletes)

    inserts_diff =
      Enum.reduce(inserts, %{}, fn {key, value}, acc ->
        Map.put(acc, key, generate_stream_diff(value))
      end)

    merged =
      Map.merge(inserts_diff, deletes, fn _key, inserts, deletes ->
        {inserts, deletes}
      end)

    cleaned =
      Enum.map(merged, fn {key, {inserts, deletes}} ->
        inverted = Enum.reverse(inserts)

        cleaned =
          Enum.reduce(deletes, inverted, fn dom_id, acc ->
            List.keydelete(acc, dom_id, 0)
          end)

        {key, cleaned}
      end)

    initial_diff =
      Enum.reduce(cleaned, @empty_diff, fn {group_key, list}, acc ->
        ins_map =
          Enum.into(list, %{}, fn {_, val} ->
            {val.id, val}
          end)

        list_diff = %Diff{
          type: :list,
          ins: ins_map,
          del: %{},
          diff: %{}
        }

        updated_diff = Map.put(acc.diff, group_key, list_diff)
        %{acc | diff: updated_diff}
      end)

    streams_state =
      Enum.map(cleaned, fn {k, v} ->
        {k, Enum.with_index(v, fn {dom_id, _}, index -> {dom_id, index} end)}
      end)

    dbg(streams_state)
    {initial_term, initial_diff, streams_state}
  end

  defp maybe_fill_deletes(inserts, deletes) do
    Enum.reduce(Map.keys(inserts), deletes, fn key, acc ->
      Map.put_new(acc, key, [])
    end)
  end

  defp generate_stream_diff(inserts) do
    Enum.reduce(Enum.reverse(inserts), [], fn {dom_id, index, element, _, updated?}, acc ->
      if updated? do
        List.keyreplace(acc, dom_id, 0, {dom_id, element})
      else
        List.insert_at(acc, index, {dom_id, element})
      end
    end)
  end

  # defp generate_stream_update_diff(inserts,deletes,stream_state) do

  #   merged =
  #     Map.merge(inserts, deletes, fn _key, inserts, deletes ->
  #       {Enum.reverse(inserts), deletes}
  #     end)
  #   Enum.reduce(merged, {}, fn {ins,del}, acc ->
  #    # {dom_id, index, element, _, updated?}
  #    Enum.reduce(ins, [], fn {dom_id, index, element, _, updated?}, acc ->
  #     if updated? do
  #       List.keyreplace(acc, dom_id, 0, {dom_id, element})
  #     else
  #       List.insert_at(acc, index, {dom_id, element})
  #     end
  #   end, [])

  #   end)
  # end

  defp generate_stream_update_diff(inserts, deletes, current_state) do
    # === Usuń elementy z state ===
    deleted_ids = MapSet.new(deletes)

    cleaned =
      Enum.reject(current_state, fn {dom_id, _index} ->
        dom_id in deleted_ids
      end)

    reindexed_cleaned =
      cleaned
      |> Enum.with_index()
      |> Enum.map(fn {{dom_id, _old_index}, new_index} ->
        {dom_id, new_index}
      end)

    # === Tworzenie mapy del: %{index => :deleted} ===
    del_map =
      deletes
      |> Enum.map(fn dom_id ->
        case List.keyfind(current_state, dom_id, 0) do
          {^dom_id, index} -> {index, :deleted}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{})

    # === Tworzenie mapy ins i aktualizacja listy ===
    {ins_map, update_del_map, updated_list} =
      Enum.reduce(inserts, {%{}, %{}, reindexed_cleaned}, fn
        {dom_id, index, value, _, true}, {ins_acc, del_acc, list_acc} ->
          {_, original_index} = List.keyfind(current_state, dom_id, 0)
          {_, new_index} = List.keyfind(reindexed_cleaned, dom_id, 0)

          delete_entry =
            if original_index, do: Map.put(del_acc, original_index, :deleted), else: del_acc

          insert_entry =
            if new_index, do: Map.put(ins_acc, new_index, value), else: ins_acc

          state_entry =
            if new_index,
              do: List.keyreplace(list_acc, dom_id, 0, {dom_id, index}),
              else: list_acc

          {
            insert_entry,
            delete_entry,
            state_entry
          }

        {dom_id, index, value, _, false}, {ins_acc, del_acc, list_acc} ->
          {
            Map.put(ins_acc, index, value),
            del_acc,
            List.insert_at(list_acc, index, {dom_id, index})
          }
      end)

    final_del_map = Map.merge(del_map, update_del_map)

    reindexed_updated_list =
      updated_list
      |> Enum.with_index()
      |> Enum.map(fn {{dom_id, _old_index}, new_index} ->
        {dom_id, new_index}
      end)

    %{
      ins: ins_map,
      del: final_del_map,
      updated_state: reindexed_updated_list
    }
  end

  defp initialize_stream_state([]), do: %{}

  defp initialize_stream_state([first_trace | _]) do
    first_trace
    |> Enum.filter(fn {_, v} -> match?(%Phoenix.LiveView.LiveStream{}, v) end)
    |> Map.new(fn {name, _} -> {name, []} end)
  end

  def calculate_diff(stream_updates, current_stream_state_list) do
    # dbg(stream_updates)
    dbg(current_stream_state_list)

    inserts = collect_updates(stream_updates, :inserts)
    deletes = collect_updates(stream_updates, :deletes)

    {diffs, updated_stream_state} =
      Enum.reduce(current_stream_state_list, {%{}, %{}}, fn {key, value}, {diff_acc, state_acc} ->
        diff =
          generate_stream_update_diff(Map.get(inserts, key, []), Map.get(deletes, key, []), value)

        {
          Map.put(diff_acc, key, %{ins: diff.ins, del: diff.del}),
          Map.put(state_acc, key, diff.updated_state)
        }
      end)

    dbg(diffs)
    dbg(updated_stream_state)
    # dbg(inserts_diff)
    # dbg(deletes)

    # final_diff =
    #   Enum.reduce(inserts_diff, @empty_diff, fn {group_key, list}, acc ->
    #     ins_map =
    #       Enum.into(list, %{}, fn {_, val, index} ->
    #         if(index == 0) do
    #           {val.id, val}
    #         else
    #           max_item_id =
    #             Enum.max_by(Keyword.get(current_stream_state_list, group_key), fn {_dom_id, id} ->
    #               id
    #             end)

    #           if max_item_id < index do
    #             {val.id, val}
    #           else
    #             {index, val}
    #           end
    #         end
    #       end)

    #     del_map =
    #       deletes
    #       |> Map.get(group_key, [])
    #       |> Enum.into(%{}, fn dom_id ->
    #         Keyword.get(current_stream_state_list, group_key)
    #         |> List.keyfind!(dom_id, 0)
    #         |> Enum.map(fn _, index -> {index, :deleted} end)
    #       end)

    #     list_diff = %LiveDebugger.App.Utils.TermDiffer.Diff{
    #       type: :list,
    #       ins: ins_map,
    #       del: del_map,
    #       diff: %{}
    #     }

    #     updated_diff = Map.put(acc.diff, group_key, list_diff)
    #     %{acc | diff: updated_diff}
    #   end)

    # Enum.each(deletes, fn)

    # dbg(final_diff)

    # final_diff
    # # Add handling deletions in initial render
  end

  @doc """
  Applies all stream updates to the initial state and returns the final result.
  """
  def apply_stream_updates(stream_data, initial_state) do
    # Collect all inserts and deletes across the stream data
    inserts_by_stream = collect_updates(stream_data, :inserts)
    #
    deletes_by_stream = collect_updates(stream_data, :deletes)
    {inserts_by_stream, deletes_by_stream}
  end

  defp collect_updates(stream_data, update_type) when update_type in [:inserts, :deletes] do
    stream_data
    |> Enum.flat_map(fn stream ->
      extract_updates_from_stream(stream, update_type)
    end)
    |> Enum.reduce(%{}, fn {name, updates}, acc ->
      Map.update(acc, name, updates, &(&1 ++ updates))
    end)
  end

  defp extract_updates_from_stream(stream, update_type) do
    Enum.flat_map(stream, fn stream_entry ->
      extract_update_entry(stream_entry, update_type)
    end)
  end

  defp extract_update_entry({name, %Phoenix.LiveView.LiveStream{}} = stream_entry, update_type) do
    case extract_update_data(stream_entry, update_type) do
      {^name, updates} when updates != [] -> [{name, updates}]
      _ -> []
    end
  end

  defp extract_update_entry(_, _) do
    []
  end

  defp extract_update_data({name, %Phoenix.LiveView.LiveStream{inserts: inserts}}, :inserts),
    do: {name, inserts}

  defp extract_update_data({name, %Phoenix.LiveView.LiveStream{deletes: deletes}}, :deletes),
    do: {name, deletes}

  defp extract_update_data(_, _), do: {nil, []}
end
