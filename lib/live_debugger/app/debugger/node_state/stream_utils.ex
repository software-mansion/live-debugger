defmodule LiveDebugger.App.Debugger.NodeState.StreamUtils do
  @moduledoc """
  Utilities for extracting Phoenix LiveView stream diffs and state
  from render traces.
  """

  @doc """
  Given a tuple of render traces, compute the base stream diff and stream state.
  """
  def build_initial_stream_diff({stream_updates, _trace}) do
    stream_traces = extract_stream_traces(stream_updates)
    stream_names = get_stream_names_map(stream_traces)

    fun_list = collect_updates_for_initial_stream(stream_traces, stream_names)
    config_list = collect_config(stream_traces)

    dbg(fun_list)

    {fun_list, config_list, stream_names}
  end

  def compute_diff(stream_updates) do
    stream_names = get_stream_names_map(stream_updates)
    fun_list = collect_updates(stream_updates)
    {fun_list, stream_names}
  end

  defp extract_stream_traces(stream_updates) do
    stream_updates
    |> Enum.sort_by(& &1.timestamp, :asc)
    |> Enum.flat_map(& &1.args)
    |> Enum.map(&Map.get(&1, :streams, []))
    |> Enum.reject(&Enum.empty?/1)
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

  defp collect_updates_for_initial_stream(update_list, stream_names) do
    update_map =
      Enum.reduce(update_list, %{}, fn update, acc ->
        process_update(acc, update, stream_names)
      end)

    fun_list =
      update_map
      |> Enum.flat_map(&flatten_stream_initial_updates/1)

    dbg(fun_list)
    fun_list
  end

  defp process_update(acc, update, stream_names) do
    Enum.reduce(stream_names, acc, fn key, acc_inner ->
      update_stream_if_present(acc_inner, update, key)
    end)
  end

  defp update_stream_if_present(acc, update, key) do
    case Map.get(update, key) do
      %Phoenix.LiveView.LiveStream{} = stream ->
        Map.update(acc, key, [], fn current ->
          apply_stream_update(current, stream)
        end)

      _ ->
        acc
    end
  end

  defp apply_stream_update(_current, %Phoenix.LiveView.LiveStream{reset?: true}) do
    []
  end

  defp apply_stream_update(current, %Phoenix.LiveView.LiveStream{
         inserts: inserts,
         deletes: deletes
       }) do
    current =
      Enum.reduce(inserts, current, fn
        {dom_id, at, data, limit, updated?}, acc ->
          [{dom_id, at, data, limit, updated?} | acc]

        _, acc ->
          acc
      end)

    Enum.reject(current, fn {dom_id, _at, _data, _limit, _updated?} -> dom_id in deletes end)
  end

  defp collect_config(update_list) do
    update_list =
      update_list
      |> Enum.map(&flatten_stream_config(&1))
      # We only need the first render because config stays the same and cannot be changed
      |> Enum.take(1)
      |> List.flatten()

    dbg(update_list)
    update_list
  end

  defp map_initial_stream_entry_to_stream_function(stream_name, inserts) do
    []
    |> maybe_add_inserts(Enum.reverse(inserts), stream_name)
  end

  defp map_stream_entry_to_stream_function(%Phoenix.LiveView.LiveStream{
         name: name,
         inserts: inserts,
         deletes: deletes,
         reset?: reset?,
         consumable?: _consumable?
       }) do
    []
    |> maybe_add_reset(reset?, name)
    # Reverse to preserve the order of inserts
    |> maybe_add_inserts(Enum.reverse(inserts), name)
    |> maybe_add_deletes(deletes, name)
  end

  def map_stream_entry_to_stream_config(
        %Phoenix.LiveView.LiveStream{
          name: name
        },
        config
      ) do
    []
    |> maybe_add_config(config, name)
  end

  defp maybe_add_config(functions, nil, _name), do: functions

  defp maybe_add_config(functions, [dom_id: fun], name) do
    functions ++ [fn socket -> Phoenix.LiveView.stream_configure(socket, name, dom_id: fun) end]
  end

  defp maybe_add_reset(functions, true, name) do
    functions ++
      [
        fn socket ->
          Phoenix.LiveView.stream(socket, name, [], reset: true)
        end
      ]
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
    Enum.map(inserts, fn {_dom_id, at, element, limit, update?} ->
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
      fn socket ->
        Phoenix.LiveView.stream_delete_by_dom_id(socket, name, dom_id)
      end
    end)
  end

  defp flatten_stream_initial_updates({stream_name, inserts}) do
    map_initial_stream_entry_to_stream_function(stream_name, inserts)
  end

  defp flatten_stream_updates(stream_entry) do
    dbg(stream_entry)

    Enum.flat_map(stream_entry, fn
      {_stream_name, %Phoenix.LiveView.LiveStream{} = stream} ->
        map_stream_entry_to_stream_function(stream)

      _ ->
        []
    end)
  end

  defp flatten_stream_config(stream_entry) do
    configured = Map.get(stream_entry, :__configured__)

    Enum.flat_map(stream_entry, fn
      {stream_name, %Phoenix.LiveView.LiveStream{} = stream} ->
        name_config = Map.get(configured, stream_name)
        map_stream_entry_to_stream_config(stream, name_config)

      _ ->
        []
    end)
  end
end
