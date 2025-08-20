defmodule LiveDebugger.Services.GarbageCollector.GenServers.TableWatcher do
  @moduledoc """
  Keeps track of processes that are being debugged and their watchers.
  """

  use GenServer

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.DebuggerMounted
  alias LiveDebugger.App.Events.DebuggerTerminated
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied

  import LiveDebugger.Helpers

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

  @spec alive_pids() :: MapSet.t(pid())
  def alive_pids() do
    GenServer.call(__MODULE__, :alive_pids)
  end

  @spec watched_pids() :: MapSet.t(pid())
  def watched_pids() do
    GenServer.call(__MODULE__, :watched_pids)
  end

  @impl true
  def handle_call(:alive_pids, _, state) do
    pids =
      state
      |> Map.filter(fn {_pid, %ProcessInfo{alive?: alive?}} -> alive? end)
      |> Map.keys()
      |> Enum.into(MapSet.new())

    {:reply, pids, state}
  end

  @impl true
  def handle_call(:watched_pids, _, state) do
    pids =
      state
      |> Map.filter(fn {_pid, %ProcessInfo{watchers: watchers}} -> not Enum.empty?(watchers) end)
      |> Map.keys()
      |> Enum.into(MapSet.new())

    {:reply, pids, state}
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
  def handle_info(%DebuggerMounted{debugged_pid: debugged_pid, debugger_pid: debugger_pid}, state) do
    state
    |> add_watcher(debugged_pid, debugger_pid)
    |> noreply()
  end

  @impl true
  def handle_info(%DebuggerTerminated{debugger_pid: debugger_pid}, state) do
    state
    |> Enum.find(fn {_, %ProcessInfo{watchers: watchers}} ->
      MapSet.member?(watchers, debugger_pid)
    end)
    |> case do
      {debugged_pid, _} ->
        state
        |> remove_watcher(debugged_pid, debugger_pid)
        |> noreply()

      nil ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  @spec update_live_view_died(state(), pid()) :: state()
  defp update_live_view_died(state, pid) do
    with {%ProcessInfo{} = info, new_state} <- Map.pop!(state, pid),
         true <- Enum.empty?(info.watchers) do
      new_state
    else
      _ ->
        state |> Map.update!(pid, &%{&1 | alive?: false})
    end
  end

  @spec add_watcher(state(), pid(), pid()) :: state()
  defp add_watcher(state, pid, watcher) when is_map_key(state, pid) do
    Map.update!(state, pid, fn info ->
      watchers = MapSet.put(info.watchers, watcher)
      %{info | watchers: watchers}
    end)
  end

  defp add_watcher(state, pid, watcher) do
    if Process.alive?(pid) do
      Map.put(state, pid, %ProcessInfo{watchers: MapSet.new([watcher])})
    else
      state
    end
  end

  @spec remove_watcher(state(), pid(), pid()) :: state()
  defp remove_watcher(state, pid, watcher) do
    Map.update!(state, pid, fn info ->
      watchers = MapSet.delete(info.watchers, watcher)
      %{info | watchers: watchers}
    end)
  end
end
