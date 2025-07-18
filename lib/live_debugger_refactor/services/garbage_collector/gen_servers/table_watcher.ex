defmodule LiveDebuggerRefactor.Services.GarbageCollector.GenServers.TableWatcher do
  use GenServer

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.App.Events.DebuggerMounted
  alias LiveDebuggerRefactor.App.Events.DebuggerTerminated
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewDied

  import LiveDebuggerRefactor.Services.Helpers

  @type state :: %{
          (watched_pid :: pid()) => [watcher_pid :: pid()]
        }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Bus.receive_events!()

    {:ok, %{}}
  end

  @impl true
  def handle_info(%LiveViewBorn{}, state) do
    # TODO: implement

    noreply(state)
  end

  @impl true
  def handle_info(%LiveViewDied{}, state) do
    # TODO: implement

    noreply(state)
  end

  @impl true
  def handle_info(%DebuggerMounted{}, state) do
    # TODO: implement

    noreply(state)
  end

  @impl true
  def handle_info(%DebuggerTerminated{}, state) do
    # TODO: implement

    noreply(state)
  end
end
