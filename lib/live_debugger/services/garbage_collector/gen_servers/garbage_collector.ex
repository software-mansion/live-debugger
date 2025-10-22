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

  @garbage_collect_interval 2000

  @type state :: %{
          garbage_collection_enabled?: boolean(),
          to_remove: %{pid() => non_neg_integer()}
        }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Bus.receive_events!()
    loop_garbage_collection()

    {:ok,
     %{
       garbage_collection_enabled?: SettingsStorage.get(:garbage_collection),
       to_remove: %{}
     }}
  end

  @impl true
  def handle_info(:garbage_collect, %{garbage_collection_enabled?: true} = state) do
    watched_pids = TableWatcher.watched_pids()
    alive_pids = TableWatcher.alive_pids()

    to_remove1 = GarbageCollectingActions.garbage_collect_traces!(state, watched_pids, alive_pids)
    to_remove2 = GarbageCollectingActions.garbage_collect_states!(state, watched_pids, alive_pids)

    loop_garbage_collection()

    to_remove = Map.intersect(to_remove1, to_remove2, fn _, cnt1, cnt2 -> min(cnt1, cnt2) end)

    {:noreply, %{state | to_remove: to_remove}}
  end

  # Handle messages related to ETS table transfers from TracesStorage
  def handle_info({:"ETS-TRANSFER", _ref, _from, _}, state) do
    {:noreply, state}
  end

  def handle_info(%UserChangedSettings{key: :garbage_collection, value: true}, state) do
    resume_garbage_collection()
    {:noreply, Map.put(state, :garbage_collection_enabled?, true)}
  end

  def handle_info(%UserChangedSettings{key: :garbage_collection, value: false}, state) do
    {:noreply, Map.put(state, :garbage_collection_enabled?, false)}
  end

  def handle_info(_, state), do: {:noreply, state}

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
