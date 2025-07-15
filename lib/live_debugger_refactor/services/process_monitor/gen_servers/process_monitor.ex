defmodule LiveDebuggerRefactor.Services.ProcessMonitor.GenServers.ProcessMonitor do
  @moduledoc """
  This module is monitoring the status of LiveView processes created by a debugged application.
  """

  use GenServer

  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.ComponentDeleted
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.ComponentCreated
  alias LiveDebugger.Structs.Trace
  alias LiveDebuggerRefactor.API.TracesStorage
  alias LiveDebuggerRefactor.API.LiveViewDebug
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebuggerRefactor.Bus

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    # TODO: change to receive_traces!/0
    :ok = Bus.receive_traces()

    {:ok, %{}}
  end

  def handle_info(%TraceReturned{id: id, function: :render, context: %{pid: pid}}, state)
      when is_map_key(state, pid) do
    case TracesStorage.get_by_id!(pid, id) do
      nil ->
        {:noreply, state}

      %Trace{cid: cid} ->
        if MapSet.member?(state[pid], cid) do
          {:noreply, state}
        else
          new_state =
            state
            |> Map.update!(pid, &MapSet.put(&1, cid))

          Bus.broadcast_event!(%ComponentCreated{node_id: cid})
          Bus.broadcast_event!(%ComponentCreated{node_id: cid}, pid)

          {:noreply, new_state}
        end
    end
  end

  def handle_info(%TraceReturned{function: :render, context: %{pid: pid}}, state) do
    Process.monitor(pid)

    {:ok, components} = LiveViewDebug.live_components(pid)
    node_ids = Enum.map(components, & &1.cid)
    new_state = Map.put(state, pid, MapSet.new(node_ids))

    Bus.broadcast_event!(%LiveViewBorn{pid: pid})

    {:noreply, new_state}
  end

  def handle_info(
        %TraceCalled{
          id: id,
          module: Phoenix.LiveView.Diff,
          function: :delete_component,
          context: %{pid: pid}
        },
        state
      )
      when is_map_key(state, pid) do
    case TracesStorage.get_by_id!(pid, id) do
      nil ->
        {:noreply, state}

      %Trace{cid: cid} ->
        if MapSet.member?(state[pid], cid) do
          new_state =
            state
            |> Map.update!(pid, &MapSet.delete(&1, cid))

          Bus.broadcast_event!(%ComponentDeleted{node_id: cid})
          Bus.broadcast_event!(%ComponentDeleted{node_id: cid}, pid)

          {:noreply, new_state}
        else
          {:noreply, state}
        end
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) when is_map_key(state, pid) do
    Bus.broadcast_event!(%LiveViewDied{pid: pid})
    {:noreply, Map.delete(state, pid)}
  end
end
