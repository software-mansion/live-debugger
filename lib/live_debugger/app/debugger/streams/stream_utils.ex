defmodule LiveDebugger.App.Debugger.Streams.StreamUtils do
  @moduledoc """
  Utilities for extracting Phoenix.LiveView.Stream diffs
  from render traces and mapping them into a list of functions.
  """

  @type live_stream_item :: %Phoenix.LiveView.LiveStream{
          name: atom(),
          dom_id: (any() -> String.t()),
          ref: String.t(),
          inserts: list(),
          deletes: list(),
          reset?: boolean(),
          consumable?: boolean()
        }

  @type stream_entry :: %{
          optional(atom()) => live_stream_item(),
          __changed__: MapSet.t(atom()),
          __configured__: %{optional(atom()) => [dom_id: (any() -> String.t())]},
          __ref__: any()
        }

  @spec extract_stream_traces([LiveDebugger.Structs.Trace.FunctionTrace.t()]) ::
          [stream_entry()]
  def extract_stream_traces(stream_updates) do
    stream_updates =
      stream_updates
      |> Enum.sort_by(& &1.timestamp, :asc)
      |> Enum.flat_map(& &1.args)
      |> Enum.map(&Map.get(&1, :streams, []))
      |> Enum.reject(&Enum.empty?/1)

    stream_updates
  end

  @spec streams_names([stream_entry()]) :: [atom()]
  def streams_names(update_list) do
    update_list
    |> Enum.flat_map(fn update ->
      update
      |> Enum.filter(fn {_key, val} -> match?(%Phoenix.LiveView.LiveStream{}, val) end)
      |> Enum.map(fn {key, _} -> key end)
    end)
    |> Enum.uniq()
  end

  @spec streams_functions([stream_entry()], [atom()]) :: [function()]
  def streams_functions(update_list, stream_names) do
    update_list
    |> Enum.reduce(%{}, fn update, acc ->
      process_update(acc, update, stream_names)
    end)
    |> Enum.flat_map(fn {stream_name, inserts} ->
      map_initial_stream_entry_to_stream_function(stream_name, inserts)
    end)
  end

  @spec stream_update_functions(live_stream_item()) :: [function()]
  def stream_update_functions(%Phoenix.LiveView.LiveStream{
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

  @spec stream_config(
          live_stream_item(),
          config :: [{:dom_id, (any() -> String.t()) | nil}]
        ) :: [function()]
  def stream_config(
        %Phoenix.LiveView.LiveStream{
          name: name
        },
        config
      ) do
    []
    |> maybe_add_config(config, name)
  end

  @spec streams_config([stream_entry()], [atom()]) :: [function()]
  def streams_config(update_list, stream_names) do
    update_list
    |> collect_stream_configs(stream_names)
    |> Enum.uniq_by(fn {name, _config} -> name end)
    |> Enum.flat_map(fn {_name, config} -> config end)
  end

  @spec collect_stream_configs([stream_entry()], [atom()]) :: [{atom(), [function()]}]
  defp collect_stream_configs(update_list, stream_names) do
    Enum.flat_map(update_list, fn update ->
      stream_names
      |> Enum.filter(&Map.has_key?(update, &1))
      |> Enum.map(fn name ->
        stream = Map.get(update, name)
        conf = Map.get(update[:__configured__] || %{}, name)
        {name, stream_config(stream, conf)}
      end)
    end)
  end

  defp process_update(acc, update, stream_names) do
    Enum.reduce(stream_names, acc, fn key, acc_inner ->
      update_stream_if_present(acc_inner, update, key)
    end)
  end

  defp update_stream_if_present(acc, update, key) do
    case Map.get(update, key) do
      %Phoenix.LiveView.LiveStream{} = stream ->
        Map.update(acc, key, apply_stream_update([], stream), fn current ->
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
    current
    |> add_inserts(Enum.reverse(inserts))
    |> remove_deleted(deletes)
  end

  defp add_inserts(current, inserts) do
    Enum.reduce(inserts, current, fn insert, acc ->
      [normalize_insert(insert) | acc]
    end)
  end

  defp normalize_insert({dom_id, at, data, limit, updated?}),
    do: {dom_id, at, data, limit, updated?}

  defp normalize_insert({dom_id, at, data, limit}), do: {dom_id, at, data, limit}
  defp normalize_insert({dom_id, at, data}), do: {dom_id, at, data}

  defp remove_deleted(current, deletes) do
    Enum.reject(current, fn
      {dom_id, _at, _data, _limit, _updated?} ->
        dom_id in deletes

      {dom_id, _at, _data, _limit} ->
        dom_id in deletes

      {dom_id, _at, _data} ->
        dom_id in deletes
    end)
  end

  defp map_initial_stream_entry_to_stream_function(stream_name, inserts) do
    []
    |> maybe_add_inserts(Enum.reverse(inserts), stream_name)
  end

  defp maybe_add_config(functions, nil, _name), do: functions
  defp maybe_add_config(functions, [dom_id: nil], _name), do: functions

  defp maybe_add_config(functions, [dom_id: fun], name) do
    functions ++
      [
        fn socket ->
          try do
            Phoenix.LiveView.stream_configure(socket, name, dom_id: fun)
          rescue
            _ -> socket
          end
        end
      ]
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
    Enum.map(inserts, fn
      {_dom_id, at, element, limit, update?} ->
        fn socket ->
          Phoenix.LiveView.stream_insert(socket, name, element,
            at: at,
            limit: limit,
            update: update?
          )
        end

      # This cases are for old LiveView versions
      {_dom_id, at, element, limit} ->
        fn socket ->
          Phoenix.LiveView.stream_insert(socket, name, element,
            at: at,
            limit: limit
          )
        end

      # For LiveView < 1.0
      {_dom_id, at, element} ->
        fn socket ->
          Phoenix.LiveView.stream_insert(socket, name, element, at: at)
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
end
