defmodule LiveDebugger.Services.CallbackTracer.Actions.State do
  @moduledoc """
  Actions responsible for saving LiveView process' state.
  """

  alias LiveDebugger.Utils.Versions
  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.Structs.Trace.FunctionTrace
  alias LiveDebugger.Structs.LvState

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged
  alias LiveDebugger.Services.CallbackTracer.Events.StreamUpdated

  @doc """
  Handles stream updates and saves state across render traces.
  - Broadcasts `StreamUpdated` events for streams that changed.
  - Checks if the trace is state changing and if so, it saves the state.
  """
  @spec maybe_save_state!(FunctionTrace.t()) :: :ok
  def maybe_save_state!(%FunctionTrace{
        pid: pid,
        function: :render,
        type: :return_from,
        args: [%{streams: streams} | _]
      }) do
    broadcast_stream_updates(pid, streams)
    do_save_state!(pid)
  end

  def maybe_save_state!(%FunctionTrace{pid: pid, function: :render, type: :return_from}) do
    do_save_state!(pid)
  end

  def maybe_save_state!(%FunctionTrace{
        pid: pid,
        function: function,
        type: type,
        args: [_, _, socket]
      })
      when function in [:mount, :handle_params] and type in [:return_from, :exception_from] do
    do_save_initial_state!(pid, socket)
  end

  if not Versions.live_component_destroyed_telemetry_supported?() do
    def maybe_save_state!(%FunctionTrace{pid: pid, function: :delete_component, type: :call}) do
      do_save_state!(pid)
    end
  end

  def maybe_save_state!(_), do: :ok

  defp do_save_state!(pid) do
    with {:ok, lv_state} <- LiveViewDebug.liveview_state(pid) do
      StatesStorage.save!(lv_state)
      Bus.broadcast_state!(%StateChanged{pid: pid}, pid)
      :ok
    end
  end

  # This is to save initial socket state in case of LiveView crash before first render in which situation
  # we won't be able to fetch the state.
  # It lacks LiveComponents info, but in situation when LiveView crashes before first render,
  # we are not able to fetch this information.
  defp do_save_initial_state!(pid, socket) do
    case StatesStorage.get!(pid) do
      %LvState{} ->
        :ok

      nil ->
        StatesStorage.save!(%LvState{pid: pid, socket: socket})
        Bus.broadcast_state!(%StateChanged{pid: pid}, pid)
        :ok
    end
  end

  defp broadcast_stream_updates(pid, streams) do
    changed = streams[:__changed__]
    configured = streams[:__configured__]

    streams
    |> Map.values()
    |> Enum.each(fn
      %Phoenix.LiveView.LiveStream{name: name} = stream ->
        if MapSet.member?(changed, name) do
          dom_id_fun =
            configured
            |> Map.get(name, [])
            |> Keyword.get(:dom_id)

          Bus.broadcast_state!(
            %StreamUpdated{
              pid: pid,
              stream: stream,
              dom_id_fun: dom_id_fun
            },
            pid
          )
        end

      _ ->
        :skip
    end)
  end
end
