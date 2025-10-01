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

  @spec register_component_created!(ProcessMonitor.state(), pid(), CommonTypes.cid()) ::
          ProcessMonitor.state()
  def register_component_created!(state, pid, cid) do
    new_state = Map.update!(state, pid, &MapSet.put(&1, cid))
    Bus.broadcast_event!(%LiveComponentCreated{cid: cid, pid: pid}, pid)

    new_state
  end

  @spec register_component_deleted!(ProcessMonitor.state(), pid(), CommonTypes.cid()) ::
          ProcessMonitor.state()
  def register_component_deleted!(state, pid, cid) do
    new_state = Map.update!(state, pid, &MapSet.delete(&1, cid))
    Bus.broadcast_event!(%LiveComponentDeleted{cid: cid, pid: pid}, pid)

    new_state
  end

  @spec register_live_view_born!(ProcessMonitor.state(), pid(), pid()) :: ProcessMonitor.state()
  def register_live_view_born!(state, pid, transport_pid) do
    Process.monitor(pid)

    Bus.broadcast_event!(%LiveViewBorn{pid: pid, transport_pid: transport_pid})

    case LiveViewDebug.live_components(pid) do
      {:ok, components} ->
        node_ids = Enum.map(components, &%Phoenix.LiveComponent.CID{cid: &1.cid})
        new_state = Map.put(state, pid, MapSet.new(node_ids))

        new_state

      _ ->
        state
    end
  end

  @spec register_live_view_died!(ProcessMonitor.state(), pid()) :: ProcessMonitor.state()
  def register_live_view_died!(state, pid) do
    new_state = Map.delete(state, pid)
    Bus.broadcast_event!(%LiveViewDied{pid: pid})

    new_state
  end
end
