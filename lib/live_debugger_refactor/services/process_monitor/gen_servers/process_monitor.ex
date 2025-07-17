defmodule LiveDebuggerRefactor.Services.ProcessMonitor.GenServers.ProcessMonitor do
  @moduledoc """
  This module is monitoring the status of LiveView processes created by a debugged application.

  For this server to function properly two services must be running and sending events:
  - `LiveDebuggerRefactor.Services.CallbackTracer` sending `TraceCalled` and `TraceReturned` events
  - `LiveDebuggerRefactor.Services.ClientCommunicator` sending `ClientConnected` (temporary name)

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

  alias LiveDebuggerRefactor.CommonTypes
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Actions, as: ProcessMonitorActions

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned

  import LiveDebuggerRefactor.Services.Helpers

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
  def handle_info(%TraceReturned{function: :render, pid: pid}, state)
      when not is_map_key(state, pid) do
    state
    |> ProcessMonitorActions.register_live_view_born!(pid)
    |> noreply()
  end

  @impl true
  def handle_info(%TraceReturned{function: :render, pid: pid, cid: cid}, state)
      when is_map_key(state, pid) do
    state
    |> maybe_register_component_created(pid, cid)
    |> noreply()
  end

  @impl true
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

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) when is_map_key(state, pid) do
    state
    |> ProcessMonitorActions.register_live_view_died!(pid)
    |> noreply()
  end

  @impl true
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
