defmodule LiveDebuggerRefactor.Services.GarbageCollector.GenServers.GarbageCollector do
  @moduledoc """
  Server for periodically collecting garbage in the LiveDebugger system.
  """

  use GenServer

  @garbage_collect_interval 2000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    if LiveDebuggerRefactor.Feature.enabled?(:garbage_collection) do
      init_garbage_collection_loop()
    end

    {:ok, []}
  end

  @spec init_garbage_collection_loop() :: {:ok, pid()}
  defp init_garbage_collection_loop() do
    Task.start(fn ->
      garbage_collection_loop()
    end)
  end

  @spec garbage_collection_loop() :: no_return()
  defp garbage_collection_loop() do
    Process.sleep(@garbage_collect_interval)
    :ok = GenServer.call(__MODULE__, :garbage_collect)
    garbage_collection_loop()
  end

  @impl true
  def handle_call(:garbage_collect, _from, state) do
    # TODO: Implement the garbage collection logic here.

    {:reply, :ok, state}
  end
end
