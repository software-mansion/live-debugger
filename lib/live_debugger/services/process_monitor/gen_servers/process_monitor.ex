defmodule LiveDebugger.Services.ProcessMonitor.GenServers.ProcessMonitor do
  @moduledoc """
  This module is monitoring the status of LiveView processes created by a debugged application.

  For this server to function properly two services must be running and sending events:
  - `LiveDebugger.Services.CallbackTracer` sending `TraceCalled` and `TraceReturned` events
  - `LiveDebugger.Services.ClientCommunicator` sending `ClientConnected` (temporary name)

  `LiveViewBorn` event is detected in two ways:
  - When a `TraceReturned` event with function `:render` is received and the process is not already registered
  - When a LiveView browser client connects via WebSocket, which sends a `ClientConnected` event

  `LiveViewDied` event is detected when a monitored LiveView process sends a `:DOWN` message.

  `LiveComponentCreated` event is detected when a `TraceReturned` event with function `:render`
  is received and the process is already registered, but the component ID (cid) is not in the state.

  `LiveComponentDeleted` event is detected when a `TraceCalled` event with module `Phoenix.LiveView.Diff`
  and function `:delete_component` is received, and the component ID (cid) is in the state.
  """

  use GenServer

  require Logger

  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Services.ProcessMonitor.Actions, as: ProcessMonitorActions

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.TraceCalled

  import LiveDebugger.Helpers

  @type state :: %{
          pid() => MapSet.t(CommonTypes.cid())
        }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Bus.receive_traces!()

    {:ok, %{}}
  end

  @impl true
  def handle_info(%TraceCalled{function: function, pid: pid, transport_pid: tpid}, state)
      when not is_map_key(state, pid) and function in [:mount, :handle_params, :render] do
    state
    |> ProcessMonitorActions.register_live_view_born!(pid, tpid)
    |> noreply()
  end

  def handle_info(%TraceCalled{function: :render, pid: pid, cid: cid}, state)
      when is_map_key(state, pid) do
    state
    |> maybe_register_component_created(pid, cid)
    |> noreply()
  end

  def handle_info(
        %TraceCalled{
          module: Phoenix.LiveView.Diff,
          function: :delete_component,
          pid: pid,
          cid: cid
        },
        state
      )
      when is_map_key(state, pid) do
    state
    |> maybe_register_component_deleted(pid, cid)
    |> noreply()
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state
    |> ProcessMonitorActions.register_live_view_died!(pid)
    |> noreply()
  end

  def handle_info(_, state) do
    noreply(state)
  end

  defp maybe_register_component_created(state, _pid, nil) do
    state
  end

  defp maybe_register_component_created(state, pid, cid) do
    if MapSet.member?(state[pid], cid) do
      state
    else
      state |> ProcessMonitorActions.register_component_created!(pid, cid)
    end
  end

  defp maybe_register_component_deleted(state, pid, cid) do
    if MapSet.member?(state[pid], cid) do
      state |> ProcessMonitorActions.register_component_deleted!(pid, cid)
    else
      Logger.info("Component #{inspect(cid)} not found in state for pid #{inspect(pid)}")
      state
    end
  end
end
