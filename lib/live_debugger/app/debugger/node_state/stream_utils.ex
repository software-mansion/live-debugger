defmodule LiveDebugger.App.Debugger.NodeState.StreamUtils do
  @moduledoc """
  Utility functions for handling Phoenix LiveView stream updates and extracting stream state from render traces.
  """
  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermDiffer.Diff
  alias LiveDebugger.App.Utils.TermParser

  @empty_diff %LiveDebugger.App.Utils.TermDiffer.Diff{
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
    # dbg(initial_state)
    # teram robimy term
    initial_diff = TermDiffer.diff(%{}, initial_state)

    # tu moze poleciec wyjatek obsluzyc
    {_, initial_term} =
      TermParser.update_by_diff(TermParser.term_to_display_tree(%{}), initial_diff)

    dbg(initial_diff)

    {inserts, deletes} = apply_stream_updates(streams_data, initial_state)
    dbg({inserts, deletes})

    inserts_diff =
      Enum.reduce(inserts, %{}, fn {key, value}, acc ->
        Map.put(acc, key, generate_stream_diff(value))
      end)

    dbg(inserts_diff)

    initial_diff =
      Enum.reduce(Enum.reverse(inserts_diff), @empty_diff, fn {group_key, list}, acc ->
        ins_map =
          Enum.into(list, %{}, fn {_, val} ->
            {val.id, val}
          end)

        list_diff = %LiveDebugger.App.Utils.TermDiffer.Diff{
          type: :list,
          ins: ins_map,
          del: %{},
          diff: %{}
        }

        updated_diff = Map.put(acc.diff, group_key, list_diff)
        %{acc | diff: updated_diff}
      end)
      
      #Add handling deletions in initial render

    {initial_term, initial_diff}

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

  defp initialize_stream_state([]), do: %{}

  defp initialize_stream_state([first_trace | _]) do
    first_trace
    |> Enum.filter(fn {_, v} -> match?(%Phoenix.LiveView.LiveStream{}, v) end)
    |> Map.new(fn {name, _} -> {name, []} end)
  end

  def calculate_diff(stream_updates, current_stream_state) do
  end

  @doc """
  Extracts streams state from render traces and returns the final state after applying all updates.

  Returns `{:ok, %{streams_state: final_state}}` where final_state is a map of stream names to their values.
  """
  def extract_streams_state_from_render_traces({state, _}) do
    streams_data =
      state
      |> Enum.sort_by(& &1.timestamp, :desc)
      |> Enum.flat_map(& &1.args)
      |> Enum.map(&Map.get(&1, :streams, []))
      |> Enum.reject(&Enum.empty?/1)

    initial_state = initialize_stream_state(streams_data)

    apply_stream_updates(streams_data, initial_state)
  end

  defp initialize_stream_state([]), do: %{}

  defp initialize_stream_state([first_trace | _]) do
    first_trace
    |> Enum.filter(fn {_, v} -> match?(%Phoenix.LiveView.LiveStream{}, v) end)
    |> Map.new(fn {name, _} -> {name, []} end)
  end

  @doc """
  Applies all stream updates to the initial state and returns the final result.
  """
  def apply_stream_updates(stream_data, initial_state) do
    # Collect all inserts and deletes across the stream data
    inserts_by_stream = collect_updates(stream_data, :inserts)
    deletes_by_stream = collect_updates(stream_data, :deletes)

    # First apply all inserts, then all deletes
    # updated_state =
    #   initial_state
    #   |> apply_inserts(inserts_by_stream)

    # # |> apply_deletes(deletes_by_stream)
    # dbg(updated_state)
    # {:ok, %{streams_state: updated_state}}
    #
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

  # defp apply_inserts(state, inserts_by_stream) do
  #   Enum.reduce(inserts_by_stream, state, fn {stream_name, inserts}, acc_state ->
  #     Enum.reduce(Enum.reverse(inserts), acc_state, fn
  #       {dom_id, index, value, _, updated?}, state when is_integer(index) ->
  #         insert_element(state, stream_name, dom_id, index, value, updated?)

  #       _, state ->
  #         state
  #     end)
  #   end)
  # end

  # defp apply_deletes(state, deletes_by_stream) do
  #   Enum.reduce(deletes_by_stream, state, fn {stream_name, deletes}, acc_state ->
  #     Enum.reduce(deletes, acc_state, fn
  #       dom_id, state when is_binary(dom_id) ->
  #         delete_element(state, stream_name, dom_id)

  #       _, state ->
  #         state
  #     end)
  #   end)
  # end

  # defp insert_element(state, stream_name, dom_id, index, value, updated?) do
  #   stream_items = Map.get(state, stream_name, [])

  #   updated_items =
  #     if updated? do
  #       List.update_at(stream_items, index, fn _ ->
  #         %{value: value, dom_id: dom_id}
  #       end)
  #     else
  #       List.insert_at(stream_items, index, %{value: value, dom_id: dom_id})
  #     end

  #   Map.put(state, stream_name, updated_items)
  # end

  # defp delete_element(state, stream_name, dom_id) do
  #   stream_items = Map.get(state, stream_name, [])

  #   case Enum.find_index(stream_items, &(&1.dom_id == dom_id)) do
  #     nil ->
  #       state

  #     index ->
  #       updated_items = List.delete_at(stream_items, index)
  #       Map.put(state, stream_name, updated_items)
  #   end
  # end
end
