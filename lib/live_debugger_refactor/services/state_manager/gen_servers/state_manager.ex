defmodule LiveDebuggerRefactor.Services.StateManager.GenServers.StateManager do
  @moduledoc """
  Server managing states of LiveView applications.
  """

  use GenServer

  alias LiveDebuggerRefactor.Services.StateManager.Actions

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Bus.receive_traces!()

    {:ok, []}
  end

  @impl true
  def handle_info(%TraceReturned{function: :render, context: %{pid: pid}}, state) do
    Actions.save_state(pid)

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}
end
