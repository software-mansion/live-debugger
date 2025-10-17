defmodule LiveDebugger.Services.ProcessMonitor.Actions do
  @moduledoc """
  This module provides actions for the ProcessMonitor service
  """

  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.Bus
  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentCreated
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentDeleted
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.GenServers.DebuggedProcessesMonitor

  @spec register_component_created!(DebuggedProcessesMonitor.state(), pid(), CommonTypes.cid()) ::
          DebuggedProcessesMonitor.state()
  def register_component_created!(state, pid, cid) do
    Bus.broadcast_event!(%LiveComponentCreated{cid: cid, pid: pid}, pid)

    Map.update!(state, pid, &MapSet.put(&1, cid))
  end

  @spec register_component_deleted!(DebuggedProcessesMonitor.state(), pid(), CommonTypes.cid()) ::
          DebuggedProcessesMonitor.state()
  def register_component_deleted!(state, pid, cid) do
    Bus.broadcast_event!(%LiveComponentDeleted{cid: cid, pid: pid}, pid)

    Map.update!(state, pid, &MapSet.delete(&1, cid))
  end

  @spec register_live_view_born!(DebuggedProcessesMonitor.state(), pid(), pid()) ::
          DebuggedProcessesMonitor.state()
  def register_live_view_born!(state, pid, transport_pid) do
    Process.monitor(pid)

    Bus.broadcast_event!(%LiveViewBorn{pid: pid, transport_pid: transport_pid})

    node_ids =
      pid
      |> LiveViewDebug.live_components()
      |> case do
        {:ok, components} -> components
        _ -> []
      end
      |> MapSet.new(&%Phoenix.LiveComponent.CID{cid: &1.cid})

    Map.put(state, pid, node_ids)
  end

  @spec register_live_view_died!(DebuggedProcessesMonitor.state(), pid()) ::
          DebuggedProcessesMonitor.state()
  def register_live_view_died!(state, pid) do
    Bus.broadcast_event!(%LiveViewDied{pid: pid})

    Map.delete(state, pid)
  end
end
