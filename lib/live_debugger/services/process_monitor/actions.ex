defmodule LiveDebugger.Services.ProcessMonitor.Actions do
  @moduledoc """
  This module provides actions for the ProcessMonitor service
  """

  alias LiveDebugger.CommonTypes
  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.Services.ProcessMonitor.GenServers.DebuggedProcessesMonitor

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentCreated
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentDeleted

  @spec register_component_created!(DebuggedProcessesMonitor.state(), pid(), CommonTypes.cid()) ::
          DebuggedProcessesMonitor.state()
  def register_component_created!(state, pid, cid) do
    Bus.broadcast_event!(%LiveComponentCreated{cid: cid, pid: pid}, pid)

    Map.update!(state, pid, &MapSet.put(&1, cid))
  end

  @spec maybe_register_component_created!(DebuggedProcessesMonitor.state(), pid()) ::
          DebuggedProcessesMonitor.state()
  def maybe_register_component_created!(state, pid) do
    current_node_ids =
      LiveViewDebug.live_components(pid)
      |> case do
        {:ok, components} -> components
        _ -> []
      end
      |> Enum.map(&%Phoenix.LiveComponent.CID{cid: &1.cid})
      |> MapSet.new()

    new_node_ids = MapSet.difference(current_node_ids, state[pid])

    if MapSet.size(new_node_ids) > 0 do
      Enum.each(new_node_ids, fn cid ->
        Bus.broadcast_event!(%LiveComponentCreated{cid: cid, pid: pid}, pid)
      end)

      Map.update!(state, pid, &MapSet.union(&1, new_node_ids))
    else
      state
    end
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
      LiveViewDebug.live_components(pid)
      |> case do
        {:ok, components} -> components
        _ -> []
      end
      |> Enum.map(&%Phoenix.LiveComponent.CID{cid: &1.cid})
      |> MapSet.new()

    Map.put(state, pid, node_ids)
  end

  @spec register_live_view_died!(DebuggedProcessesMonitor.state(), pid()) ::
          DebuggedProcessesMonitor.state()
  def register_live_view_died!(state, pid) do
    Bus.broadcast_event!(%LiveViewDied{pid: pid})

    Map.delete(state, pid)
  end
end
