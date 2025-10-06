defmodule LiveDebugger.App.Debugger.NodeState.StreamUtils do
  @moduledoc """
  Utility functions for handling stream updates and extracting stream state from render traces.
  """

  def extract_streams_state_from_render_traces({state, _}) do
    stream_from_render =
      state
      |> Enum.sort(fn a, b -> a.timestamp > b.timestamp end)
      |> Enum.map(& &1.args)
      |> List.flatten()
      |> Enum.map(&Map.get(&1, :streams, []))
      |> Enum.reject(&Enum.empty?/1)

    dbg(stream_from_render)

    innitial_stream_state =
      stream_from_render
      |> List.first()
      |> case do
        nil ->
          %{}

        first_trace ->
          first_trace
          |> Enum.filter(fn {_name, v} -> match?(%Phoenix.LiveView.LiveStream{}, v) end)
          |> Map.new(fn {name, _} -> {name, []} end)
      end

    apply_stream_updates(stream_from_render, innitial_stream_state)
  end

  defp get_updates_from_render(stream_from_render, update_type)
       when update_type in [:inserts, :deletes] do
    stream_from_render
    |> Enum.map(fn el ->
      Enum.flat_map(el, fn
        {_name, %Phoenix.LiveView.LiveStream{inserts: inserts}} when update_type == :inserts ->
          inserts

        {_name, %Phoenix.LiveView.LiveStream{deletes: deletes}} when update_type == :deletes ->
          deletes

        _ ->
          []
      end)
    end)
  end

  def apply_stream_updates(stream_from_render, current_stream_state) do
    inserts = get_updates_from_render(stream_from_render, :inserts)
    deletes = get_updates_from_render(stream_from_render, :deletes)

    build_streams_map(current_stream_state, inserts, deletes)
  end

  defp insert_stream_element(key, index, value, updated?, current_stream_state) do
    old_list = Map.get(current_stream_state, key, [])

    new_list =
      if updated? do
        newlist = List.update_at(old_list, index, fn _ -> value end)
        dbg(newlist)
        newlist
      else
        List.insert_at(old_list, index, value)
      end

    Map.put(current_stream_state, key, new_list)
  end

  defp delete_stream_element(key, index, current_stream_state) do
    old_list = Map.get(current_stream_state, key, [])
    new_list = List.delete_at(old_list, index)
    Map.put(current_stream_state, key, new_list)
  end

  defp build_streams_map(current_stream_state, inserts, deletes) do
    updated_streams =
      inserts
      |> Enum.reduce(current_stream_state, fn el, acc_streams ->
        Enum.reduce(el, acc_streams, fn
          {dom_id, index, value, _, updated?}, acc when is_integer(index) ->
            key = get_stream_name_from_dom_id(dom_id)
            insert_stream_element(key, index, value, updated?, acc)

          [], acc ->
            acc
        end)
      end)

    updated_streams =
      deletes
      |> Enum.reduce(updated_streams, fn el, acc_streams ->
        Enum.reduce(el, acc_streams, fn
          dom_id, acc ->
            key = get_stream_name_from_dom_id(dom_id)
            index = get_index_from_dom_id(dom_id)
            delete_stream_element(key, index, acc)
        end)
      end)

    {:ok, %{streams_state: updated_streams}}
  end

  defp get_stream_name_from_dom_id(key) do
    key
    |> String.split("-")
    |> List.first()
    |> String.to_atom()
  end

  defp get_index_from_dom_id(dom_id) do
    dom_id
    |> String.split("-", parts: 2)
    |> List.last()
    |> String.to_integer()
  end
end
