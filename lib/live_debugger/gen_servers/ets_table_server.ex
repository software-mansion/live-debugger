defmodule LiveDebugger.GenServers.EtsTableServer do
  @moduledoc """
  This gen_server is responsible for managing ETS tables.

  It sends `{:process_status, {:dead, pid}}` to the process status topic.

  ## Dead View Mode
  When in dead view mode, the gen_server will send `{:process_status, {:dead, pid}}` to the process status topic when a process dies.
  It will wait for all watchers to be removed and then delete the ETS table and sends `{:process_status, {:dead, pid}}` to the process status topic.

  ## Garbage Collection
  The gen_server will periodically check the size of ETS tables and trim them if they exceed a certain size.
  To adjust the size of the ETS tables, you can set the `:approx_table_max_size` in your config (which is in megabytes).

  Important! This is an approximate value, so the actual size of the table may exceed this value.
  """

  defmodule TableInfo do
    @moduledoc """
    - `table`: ETS table reference.
    - `alive?`: Indicates if the process is alive.
    - `watchers`: Set of pids that are watching this table.
    """
    defstruct [:table, alive?: true, watchers: MapSet.new()]

    @type t() :: %__MODULE__{
            alive?: boolean(),
            table: :ets.table(),
            watchers: MapSet.t()
          }
  end

  use GenServer

  alias __MODULE__.TableInfo
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.Utils.Memory

  @type state() :: %{pid() => TableInfo.t()}

  @ets_table_name :lvdbg_traces
  @garbage_collect_interval 2000
  @megabyte_unit 1_048_576

  ## API

  @callback table(pid :: pid()) :: :ets.table()
  @callback watch(pid :: pid()) :: :ok | {:error, term()}

  @doc """
  Returns ETS table reference.
  It creates table if none is associated with given pid
  """
  @spec table(pid :: pid()) :: :ets.table()
  def table(pid) when is_pid(pid), do: impl().table(pid)

  @doc """
  Adds watcher to indicate when to delete table from ETS.
  It uses pid of process which the function was called.
  """
  @spec watch(pid :: pid()) :: :ok | {:error, term()}
  def watch(pid) when is_pid(pid) do
    impl().watch(pid)
  end

  ## GenServer

  @doc false
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    if LiveDebugger.Feature.enabled?(:garbage_collection) do
      init_garbage_collection_loop()
    end

    {:ok, %{}}
  end

  # This is for debugged processes monitored
  @impl true
  def handle_info({:DOWN, _, :process, closed_pid, _}, state)
      when is_map_key(state, closed_pid) do
    if LiveDebugger.Feature.enabled?(:dead_view_mode) do
      PubSubUtils.process_status_topic()
      |> PubSubUtils.broadcast({:process_status, {:died, closed_pid}})
    end

    state =
      state
      |> Map.update!(closed_pid, fn table_info -> %{table_info | alive?: false} end)
      |> maybe_delete_ets_table(closed_pid)

    {:noreply, state}
  end

  # This is for watchers processes
  @impl true
  def handle_info({:DOWN, _, :process, closed_pid, _}, state) do
    {updated_state, touched_pids} = remove_watcher(state, closed_pid)

    updated_state =
      touched_pids
      |> Enum.reduce(updated_state, fn pid, state_acc ->
        maybe_delete_ets_table(state_acc, pid)
      end)

    {:noreply, updated_state}
  end

  @impl true
  def handle_call(:garbage_collect, _from, state) do
    state
    |> Enum.map(fn {_, %TableInfo{table: table} = table_info} ->
      {table_info, Memory.table_size(table)}
    end)
    |> Enum.each(fn {table_info, size} ->
      cond do
        trim_non_watched_table?(table_info, size) ->
          trim_ets_table(table_info.table, max_table_size(:non_watched))

        trim_watched_table?(table_info, size) ->
          trim_ets_table(table_info.table, max_table_size(:watched))

        true ->
          :ok
      end
    end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_or_create_table, pid}, _from, state) do
    case Map.get(state, pid) do
      nil ->
        ref = create_ets_table()
        Process.monitor(pid)
        {:reply, ref, Map.put(state, pid, %TableInfo{table: ref})}

      %TableInfo{table: ref} ->
        {:reply, ref, state}
    end
  end

  @impl true
  def handle_call({:watch, pid}, {watcher, _}, state) do
    case Map.get(state, pid) do
      %TableInfo{} ->
        updated_state = update_watchers(state, pid, &MapSet.put(&1, watcher))

        Process.monitor(watcher)

        {:reply, :ok, updated_state}

      _ ->
        {:reply, {:error, :process_not_found}, state}
    end
  end

  defp impl() do
    Application.get_env(:live_debugger, :ets_table_server, __MODULE__.Impl)
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.GenServers.EtsTableServer

    @server_module LiveDebugger.GenServers.EtsTableServer
    @call_timeout 1000

    @impl true
    def table(pid) do
      GenServer.call(@server_module, {:get_or_create_table, pid}, @call_timeout)
    end

    @impl true
    def watch(pid) do
      if LiveDebugger.Feature.enabled?(:dead_view_mode) do
        GenServer.call(@server_module, {:watch, pid}, @call_timeout)
      else
        {:error, :not_in_dead_view_mode}
      end
    end
  end

  @spec init_garbage_collection_loop() :: {:ok, pid()}
  defp init_garbage_collection_loop() do
    Task.start(fn ->
      garbage_collection_loop()
    end)
  end

  @spec garbage_collection_loop() :: :ok
  defp garbage_collection_loop() do
    Process.sleep(@garbage_collect_interval)
    :ok = GenServer.call(__MODULE__, :garbage_collect)
    garbage_collection_loop()
  end

  @spec trim_non_watched_table?(TableInfo.t(), non_neg_integer()) :: boolean()
  defp trim_non_watched_table?(table_info, size) do
    Enum.empty?(table_info.watchers) and size > max_table_size(:non_watched)
  end

  @spec trim_watched_table?(TableInfo.t(), non_neg_integer()) :: boolean()
  defp trim_watched_table?(table_info, size) do
    not Enum.empty?(table_info.watchers) and size > max_table_size(:watched)
  end

  @spec create_ets_table() :: :ets.table()
  defp create_ets_table() do
    :ets.new(@ets_table_name, [:ordered_set, :public])
  end

  @spec maybe_delete_ets_table(state(), pid()) :: state()
  defp maybe_delete_ets_table(state, pid) do
    with {%TableInfo{alive?: false} = table_info, updated_state} <- Map.pop(state, pid),
         true <- Enum.empty?(table_info.watchers) do
      PubSubUtils.process_status_topic()
      |> PubSubUtils.broadcast({:process_status, {:dead, pid}})

      :ets.delete(table_info.table)
      updated_state
    else
      _ ->
        state
    end
  end

  @spec remove_watcher(state(), pid()) :: {updated_state :: state(), touched_pids :: [pid()]}
  defp remove_watcher(state, watcher) when is_pid(watcher) do
    Enum.reduce(state, {state, []}, fn {pid, %{watchers: watchers}}, {state_acc, pids} ->
      if Enum.member?(watchers, watcher) do
        updated_state = update_watchers(state_acc, pid, &MapSet.delete(&1, watcher))

        {updated_state, [pid | pids]}
      else
        {state_acc, pids}
      end
    end)
  end

  @spec update_watchers(state(), pid(), (MapSet.t() -> MapSet.t())) :: state()
  defp update_watchers(state, pid, update_fn) when is_map_key(state, pid) do
    table_info = Map.get(state, pid)
    Map.put(state, pid, %{table_info | watchers: update_fn.(table_info.watchers)})
  end

  @spec trim_ets_table(:ets.table(), non_neg_integer()) :: :ok
  defp trim_ets_table(table, max_size) when is_integer(max_size) do
    :ets.safe_fixtable(table, true)

    # Try catch is used for early return from `foldl` since it doesn't support `:halt` | `:continue`.
    try do
      :ets.foldl(&foldl_record_sizes(&1, &2, max_size), 0, table)
    catch
      {:key, key} ->
        :ets.select_delete(table, [{{:"$1", :_}, [{:>, :"$1", key}], [true]}])
    end

    :ets.safe_fixtable(table, false)
    :ok
  end

  @spec foldl_record_sizes({term(), term()}, non_neg_integer(), non_neg_integer()) ::
          non_neg_integer()
  defp foldl_record_sizes({key, _} = record, acc, max_size) do
    size = Memory.term_size(record)

    if acc + size > max_size do
      throw({:key, key})
    else
      acc + size
    end
  end

  # Ets tables might exceed the maximum size since these are approximate values (e.g. 10MB might have 20MB of data).
  @spec max_table_size(:watched | :non_watched) :: non_neg_integer()
  defp max_table_size(type) when type in [:watched, :non_watched] do
    multiplier =
      case type do
        :watched -> 1
        :non_watched -> 0.1
      end

    Application.get_env(:live_debugger, :approx_table_max_size, 10)
    |> Kernel.*(@megabyte_unit)
    |> Kernel.*(multiplier)
    |> round()
  end
end
