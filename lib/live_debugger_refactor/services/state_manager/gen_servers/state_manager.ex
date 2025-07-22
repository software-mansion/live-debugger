defmodule LiveDebuggerRefactor.Services.StateManager.GenServers.StateManager do
  @moduledoc """
  Server managing states of LiveView applications.
  """

  use GenServer

  alias LiveDebuggerRefactor.Services.StateManager.Actions

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveComponentDeleted

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Bus.receive_traces!()
    Bus.receive_events!()

    {:ok, []}
  end

  @impl true
  def handle_info(%TraceReturned{function: :render, pid: pid}, state) do
    Actions.save_state!(pid)

    {:noreply, state}
  end

  @impl true
  def handle_info(%LiveComponentDeleted{pid: pid}, state) do
    Actions.save_state!(pid)

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}
end
