defmodule LiveDebuggerRefactor.Services.ProcessMonitor.GenServers.ProcessMonitor do
  @moduledoc """
  This module is monitoring the status of LiveView processes created by a debugged application.
  """

  use GenServer

  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.{
    LiveViewBorn,
    LiveViewDied,
    ComponentCreated,
    ComponentDeleted
  }

  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.{TraceCalled, TraceReturned}
  alias LiveDebuggerRefactor.API.LiveViewDebug
  alias LiveDebuggerRefactor.Bus

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # TODO: change to receive_traces!/0
    :ok = Bus.receive_traces()

    {:ok, %{}}
  end

  @impl true
  def handle_info(%TraceReturned{function: :render, cid: cid, context: %{pid: pid}}, state)
      when is_map_key(state, pid) and not is_nil(cid) do
    if registered_component?(state, pid, cid) do
      {:noreply, state}
    else
      new_state = state |> update_component_created(pid, cid)
      {:noreply, new_state}
    end
  end

  @impl true
  def handle_info(%TraceReturned{function: :render, cid: nil, context: %{pid: pid}}, state)
      when not is_map_key(state, pid) do
    new_state = state |> update_live_view_born(pid)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(
        %TraceCalled{
          module: Phoenix.LiveView.Diff,
          function: :delete_component,
          cid: cid,
          context: %{pid: pid}
        },
        state
      )
      when is_map_key(state, pid) do
    if registered_component?(state, pid, cid) do
      new_state = state |> update_component_deleted(pid, cid)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) when is_map_key(state, pid) do
    new_state = state |> update_live_view_died(pid)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp registered_component?(state, pid, cid) do
    MapSet.member?(state[pid], cid)
  end

  defp update_component_created(state, pid, cid) do
    Bus.broadcast_event!(%ComponentCreated{node_id: cid}, pid)
    Map.update!(state, pid, &MapSet.put(&1, cid))
  end

  defp update_component_deleted(state, pid, cid) do
    Bus.broadcast_event!(%ComponentDeleted{node_id: cid}, pid)
    Map.update!(state, pid, &MapSet.delete(&1, cid))
  end

  defp update_live_view_born(state, pid) do
    Process.monitor(pid)

    {:ok, components} = LiveViewDebug.live_components(pid)
    node_ids = Enum.map(components, &%Phoenix.LiveComponent.CID{cid: &1.cid})

    Bus.broadcast_event!(%LiveViewBorn{pid: pid})

    Map.put(state, pid, MapSet.new(node_ids))
  end

  defp update_live_view_died(state, pid) do
    Bus.broadcast_event!(%LiveViewDied{pid: pid})
    Map.delete(state, pid)
  end
end
