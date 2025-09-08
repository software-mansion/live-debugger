defmodule LiveDebugger.Services.GarbageCollector.GenServers.GarbageCollector do
  @moduledoc """
  Server for periodically collecting garbage in the LiveDebugger system.
  """

  use GenServer
  alias LiveDebugger.API.SettingsStorage

  alias LiveDebugger.Services.GarbageCollector.GenServers.TableWatcher

  alias LiveDebugger.Services.GarbageCollector.Actions.GarbageCollecting,
    as: GarbageCollectingActions

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.UserChangedSettings
  alias LiveDebugger.Services.GarbageCollector.Events.GarbageCollected

  @garbage_collect_interval 2000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Bus.receive_events!()
    garbage_collection_enabled? = SettingsStorage.get(:garbage_collection)
    loop_garbage_collection()

    {:ok,
     %{
       garbage_collection_enabled?: garbage_collection_enabled?
     }}
  end

  @impl true
  def handle_info(:garbage_collect, %{garbage_collection_enabled?: true} = state) do
    watched_pids = TableWatcher.watched_pids()
    alive_pids = TableWatcher.alive_pids()

    traces_collected = GarbageCollectingActions.garbage_collect_traces!(watched_pids, alive_pids)
    states_collected = GarbageCollectingActions.garbage_collect_states!(watched_pids, alive_pids)

    if traces_collected or states_collected do
      Bus.broadcast_event!(%GarbageCollected{})
    end

    loop_garbage_collection()

    {:noreply, state}
  end

  # Handle messages related to ETS table transfers from TracesStorage
  @impl true
  def handle_info({:"ETS-TRANSFER", _ref, _from, _}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(%UserChangedSettings{key: :garbage_collection, value: true}, state) do
    resume_garbage_collection()
    {:noreply, Map.put(state, :garbage_collection_enabled?, true)}
  end

  @impl true
  def handle_info(%UserChangedSettings{key: :garbage_collection, value: false}, state) do

    {:noreply, Map.put(state, :garbage_collection_enabled?, false)}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp loop_garbage_collection() do
    Process.send_after(
      self(),
      :garbage_collect,
      @garbage_collect_interval
    )
  end

  defp resume_garbage_collection() do
    send(
      self(),
      :garbage_collect
    )
  end
end
