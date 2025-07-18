defmodule LiveDebuggerRefactor.Services.GarbageCollector.GenServers.TableWatcher do
  @moduledoc """
  Keeps track of processes that are being debugged and their watchers.
  """

  use GenServer

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.App.Events.DebuggerMounted
  alias LiveDebuggerRefactor.App.Events.DebuggerTerminated
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewDied

  import LiveDebuggerRefactor.Services.Helpers

  defmodule ProcessInfo do
    @moduledoc """
    - `alive?`: Indicates if the process is alive.
    - `watchers`: Set of pids that are watching this process.
    """
    defstruct alive?: true, watchers: MapSet.new()

    @type t() :: %__MODULE__{
            alive?: boolean(),
            watchers: MapSet.t(pid())
          }
  end

  @type state :: %{pid() => ProcessInfo.t()}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Bus.receive_events!()

    {:ok, %{}}
  end

  def alive?(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:alive?, pid})
  end

  def watched?(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:watched?, pid})
  end

  @impl true
  def handle_call({:alive?, pid}, _, state) do
    case Map.fetch(state, pid) do
      {:ok, %ProcessInfo{alive?: alive?}} ->
        {:reply, alive?, state}

      :error ->
        {:reply, false, state}
    end
  end

  @impl true
  def handle_call({:watched?, pid}, _, state) do
    case Map.fetch(state, pid) do
      {:ok, %ProcessInfo{watchers: watchers}} ->
        {:reply, not Enum.empty?(watchers), state}

      :error ->
        {:reply, false, state}
    end
  end

  @impl true
  def handle_info(%LiveViewBorn{pid: pid}, state) when not is_map_key(state, pid) do
    state
    |> Map.put(pid, %ProcessInfo{})
    |> noreply()
  end

  @impl true
  def handle_info(%LiveViewDied{pid: pid}, state) when is_map_key(state, pid) do
    state
    |> update_live_view_died(pid)
    |> noreply()
  end

  @impl true
  def handle_info(%DebuggerMounted{debugged_pid: debugged_pid, debugger_pid: debugger_pid}, state)
      when is_map_key(state, debugged_pid) do
    state
    |> add_watcher(debugged_pid, debugger_pid)
    |> noreply()
  end

  @impl true
  def handle_info(
        %DebuggerTerminated{debugged_pid: debugged_pid, debugger_pid: debugger_pid},
        state
      )
      when is_map_key(state, debugged_pid) do
    state
    |> remove_watcher(debugged_pid, debugger_pid)
    |> noreply()
  end

  @impl true
  def handle_info(_, state) do
    noreply(state)
  end

  defp update_live_view_died(state, pid) do
    with {%ProcessInfo{} = info, new_state} <- Map.pop!(state, pid),
         true <- Enum.empty?(info.watchers) do
      new_state
    else
      _ ->
        state |> Map.update!(pid, &%{&1 | alive?: false})
    end
  end

  defp add_watcher(state, pid, watcher) do
    state
    |> Map.update!(pid, fn info ->
      watchers = MapSet.put(info.watchers, watcher)
      %{info | watchers: watchers}
    end)
  end

  defp remove_watcher(state, pid, watcher) do
    state
    |> Map.update!(pid, fn info ->
      watchers = MapSet.delete(info.watchers, watcher)
      %{info | watchers: watchers}
    end)
  end
end
