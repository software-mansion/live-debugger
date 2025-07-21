defmodule LiveDebuggerRefactor.Services.GarbageCollector.GenServers.GarbageCollector do
  @moduledoc """
  Server for periodically collecting garbage in the LiveDebugger system.
  """

  use GenServer

  alias LiveDebuggerRefactor.Services.GarbageCollector.Actions.GarbageCollecting,
    as: GarbageCollectingActions

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.Services.GarbageCollector.Events.GarbageCollected

  @garbage_collect_interval 2000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    if LiveDebuggerRefactor.Feature.enabled?(:garbage_collection) do
      Task.start(&garbage_collection_loop/0)
    end

    {:ok, []}
  end

  @impl true
  def handle_call(:garbage_collect, _from, state) do
    traces_collected = GarbageCollectingActions.garbage_collect_traces!()
    states_collected = GarbageCollectingActions.garbage_collect_states!()

    if traces_collected or states_collected do
      Bus.broadcast_event!(%GarbageCollected{})
    end

    {:reply, :ok, state}
  end

  @spec garbage_collection_loop() :: no_return()
  defp garbage_collection_loop() do
    Process.sleep(@garbage_collect_interval)
    :ok = GenServer.call(__MODULE__, :garbage_collect)
    garbage_collection_loop()
  end
end
