defmodule LiveDebugger.Services.ProcessMonitor.Actions do
  @moduledoc """
  This module provides actions for the ProcessMonitor service
  """

  alias LiveDebugger.CommonTypes
  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.Services.ProcessMonitor.GenServers.ProcessMonitor

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentCreated
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentDeleted
  alias LiveDebugger.Services.ProcessMonitor.Events.DebuggerTerminated

  @spec register_component_created!(ProcessMonitor.state(), pid(), CommonTypes.cid()) ::
          ProcessMonitor.state()
  def register_component_created!(state, pid, cid) do
    new_debugged = Map.update!(state.debugged, pid, &MapSet.put(&1, cid))
    Bus.broadcast_event!(%LiveComponentCreated{cid: cid, pid: pid}, pid)

    %{state | debugged: new_debugged}
  end

  @spec register_component_deleted!(ProcessMonitor.state(), pid(), CommonTypes.cid()) ::
          ProcessMonitor.state()
  def register_component_deleted!(state, pid, cid) do
    new_debugged = Map.update!(state.debugged, pid, &MapSet.delete(&1, cid))
    Bus.broadcast_event!(%LiveComponentDeleted{cid: cid, pid: pid}, pid)

    %{state | debugged: new_debugged}
  end

  @spec register_live_view_born!(ProcessMonitor.state(), pid(), pid()) :: ProcessMonitor.state()
  def register_live_view_born!(state, pid, transport_pid) do
    Process.monitor(pid)

    Bus.broadcast_event!(%LiveViewBorn{pid: pid, transport_pid: transport_pid})

    node_ids =
      LiveViewDebug.live_components(pid)
      |> case do
        {:ok, components} -> components
        _ -> []
      end
      |> Enum.map(&%Phoenix.LiveComponent.CID{cid: &1.cid})
      |> MapSet.new()

    new_debugged = Map.put(state.debugged, pid, node_ids)
    %{state | debugged: new_debugged}
  end

  @spec register_live_view_died!(ProcessMonitor.state(), pid()) :: ProcessMonitor.state()
  def register_live_view_died!(state, pid) do
    new_debugged = Map.delete(state.debugged, pid)
    Bus.broadcast_event!(%LiveViewDied{pid: pid})

    %{state | debugged: new_debugged}
  end

  @spec register_debugger_mounted(ProcessMonitor.state(), pid()) :: ProcessMonitor.state()
  def register_debugger_mounted(state, pid) do
    Process.monitor(pid)
    new_debugger = MapSet.put(state.debugger, pid)

    %{state | debugger: new_debugger}
  end

  @spec register_debugger_terminated!(ProcessMonitor.state(), pid()) :: ProcessMonitor.state()
  def register_debugger_terminated!(state, pid) do
    new_debugger = MapSet.delete(state.debugger, pid)
    Bus.broadcast_event!(%DebuggerTerminated{debugger_pid: pid})

    %{state | debugger: new_debugger}
  end
end
