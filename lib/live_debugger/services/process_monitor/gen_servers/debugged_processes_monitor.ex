defmodule LiveDebugger.Services.ProcessMonitor.GenServers.DebuggedProcessesMonitor do
  @moduledoc """
  This module is monitoring the status of LiveView processes created by a debugged application.

  For this server to function properly listed services must be running and sending events:
  - `LiveDebugger.Services.CallbackTracer` sending `TraceCalled` event
  - `LiveDebugger.Services.TelemetryHandler` sending `TelemetryEmitted` event (for :phoenix_live_view versions >= 1.1.0)

  `LiveViewBorn` event is detected when `TraceCalled` event with functions `:mount`, `:handle_params` or `:render` is received
  and the process is not already registered

  `LiveViewDied` event is detected when a monitored LiveView process sends a `:DOWN` message.

  `LiveComponentCreated` event is detected when a `TraceCalled` event with function `:render`
  is received and the process is already registered, but the component ID (cid) is not in the state.

  `LiveComponentDeleted` event is detected when:
  - (for `:phoenix_live_view` versions < 1.1.0) a `TraceCalled` event with module `Phoenix.LiveView.Diff`
  and function `:delete_component` is received, and the component ID (cid) is in the state.
  - (for `:phoenix_live_view` versions >= 1.1.0) a `TelemetryEmitted` event of type `:destroyed`
  and source `:live_component` is received, and the component ID (cid) is in the state.
  """

  use GenServer

  require Logger

  alias LiveDebugger.Utils.Versions
  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Services.ProcessMonitor.Actions, as: ProcessMonitorActions

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebugger.Services.TelemetryHandler.Events.TelemetryEmitted

  import LiveDebugger.Helpers

  @type state :: %{
          pid() => MapSet.t(CommonTypes.cid())
        }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Bus.receive_events!()
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

  if Versions.live_component_destroyed_telemetry_supported?() do
    def handle_info(
          %TelemetryEmitted{source: :live_component, type: :destroyed, pid: pid, cid: cid},
          state
        )
        when is_map_key(state, pid) do
      state
      |> maybe_register_component_deleted(pid, cid)
      |> noreply()
    end
  else
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
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state
    |> ProcessMonitorActions.register_live_view_died!(pid)
    |> noreply()
  end

  def handle_info(_, state), do: {:noreply, state}

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
