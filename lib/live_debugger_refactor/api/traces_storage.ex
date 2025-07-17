defmodule LiveDebuggerRefactor.API.TracesStorage do
  @moduledoc """
  API for managing traces storage. In order to properly use invoke `init/0` at the start of application.
  It uses Erlang's ETS (Erlang Term Storage).
  """

  alias LiveDebuggerRefactor.Structs.Trace
  alias LiveDebuggerRefactor.CommonTypes

  @typedoc """
  Pid is used to store mapping to table references.
  It identifies ETS tables managed by EtsTableServer.
  """
  @type ets_table_id() :: pid()
  @type ets_continuation() :: term()
  @type table_identifier() :: ets_table_id() | reference()

  @callback init() :: :ok
  @callback insert(Trace.t()) :: true
  @callback insert!(table_ref :: reference(), Trace.t()) :: true
  @callback get_by_id!(table_identifier(), trace_id :: integer()) :: Trace.t() | nil
  @callback get!(table_identifier(), opts :: keyword()) ::
              {[Trace.t()], ets_continuation()} | :end_of_table
  @callback clear!(table_identifier(), node_id :: pid() | CommonTypes.cid() | nil) :: true
  @callback get_table(ets_table_id()) :: reference()
  @callback delete_table!(table_identifier()) :: boolean()
  @callback get_all_tables() :: [reference()]

  defguard is_table_identifier(id) when is_pid(id) or is_reference(id)

  @doc """
  Initializes ets table.
  It should be called when application starts.
  """
  @spec init() :: :ok
  def init(), do: impl().init()

  @doc """
  Inserts a new trace into the storage.
  It has worse performance then `insert/2` as it has to perform lookup for reference.
  It stores the trace in table associated with `pid` given in `Trace` struct.
  """
  @spec insert(Trace.t()) :: true
  def insert(%Trace{} = trace) do
    impl().insert(trace)
  end

  @doc """
  Inserts a new trace into the storage into an existing table indicated by a given reference.
  It has better performance then `insert/1` as it does not perform lookup for reference.
  In order to use it properly you have to store the reference returned by `get_table/1`.
  """
  @spec insert!(table_ref :: reference(), Trace.t()) :: true
  def insert!(table_ref, %Trace{} = trace) when is_reference(table_ref) do
    impl().insert!(table_ref, trace)
  end

  @doc """
  Gets a trace of a process from the storage by `trace_id`.

    * `table_id` - PID or reference to an existing table. Using reference increases performance as it skips lookup step.
    * `trace_id` - Id of a trace stored in a table.
  """
  @spec get_by_id!(table_identifier(), trace_id :: integer()) :: Trace.t() | nil
  def get_by_id!(table_id, trace_id)
      when is_table_identifier(table_id) and is_integer(trace_id) do
    impl().get_by_id!(table_id, trace_id)
  end

  @doc """
  Returns traces of a process with optional filters.

    * `table_id` - PID or reference to an existing table. Using reference increases performance as it skips lookup step.

  ## Options
    * `:node_id` - PID or CID to filter traces by
    * `:limit` - Maximum number of traces to return (default: 100)
    * `:cont` - Used to get next page of items in the following queries
    * `:functions` - List of function names to filter traces by e.g ["handle_info/2", "render/1"]
    * `:search_query` - String to filter traces by, performs a case-sensitive substring search on the entire Trace struct
  """
  @spec get!(table_identifier(), opts :: keyword()) ::
          {[Trace.t()], ets_continuation()} | :end_of_table
  def get!(table_id, opts \\ []) when is_table_identifier(table_id) and is_list(opts) do
    impl().get!(table_id, opts)
  end

  @doc """
  Deletes traces for a given node_id. If node_id is nil, it deletes all traces for a given table.

    * `table_id` - PID or reference to an existing table. Using reference increases performance as it skips lookup step.
    * `node_id` - PID or CID which identifies node. If nil, it deletes all traces for a given table.
  """
  @spec clear!(table_identifier(), node_id :: pid() | CommonTypes.cid() | nil) :: true
  def clear!(table_id, node_id \\ nil) when is_table_identifier(table_id) do
    impl().clear!(table_id, node_id)
  end

  @doc """
  Returns table reference for a given process.
  It can be used in other storage operations to increase performance.
  In order to use it properly you have to store the reference for later usage.
  """
  @spec get_table(ets_table_id()) :: reference() | nil
  def get_table(pid) when is_pid(pid) do
    impl().get_table(pid)
  end

  @doc """
  Removes table for a given process from the storage

    * `table_id` - PID or reference to an existing table. Using reference increases performance as it skips lookup step.
  """
  @spec delete_table!(table_identifier()) :: boolean()
  def delete_table!(table_id) when is_table_identifier(table_id) do
    impl().delete_table!(table_id)
  end

  @doc """
  Returns all table references
  """
  @spec get_all_tables() :: [{ets_table_id(), reference()}]
  def get_all_tables() do
    impl().get_all_tables()
  end

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_traces_storage,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebuggerRefactor.API.TracesStorage

    alias Phoenix.LiveComponent.CID
    alias LiveDebuggerRefactor.API.TracesStorage

    @default_limit 100
    @traces_table_name :lvdbg_traces
    @processes_table_name :lvdbg_traces_processes

    @type ets_elem() :: {integer(), Trace.t()}
    @type ets_continuation() :: TracesStorage.ets_continuation()
    @type ets_table_id() :: TracesStorage.ets_table_id()
    @type table_identifier() :: TracesStorage.table_identifier()

    @impl true
    def init() do
      :ets.new(@processes_table_name, [:named_table, :public, :ordered_set])

      :ok
    end

    @impl true
    def insert(%Trace{pid: pid, id: id} = trace) do
      pid
      |> ets_table()
      |> :ets.insert({id, trace})
    end

    @impl true
    def insert!(table_ref, %Trace{id: id} = trace) do
      table_ref
      |> :ets.insert({id, trace})
    end

    @impl true
    def get_by_id!(table_id, trace_id) do
      table_id
      |> ets_table()
      |> :ets.lookup(trace_id)
      |> case do
        [] -> nil
        [{_id, trace}] -> trace
      end
    end

    @impl true
    def get!(table_id, opts \\ []) do
      search_query = Keyword.get(opts, :search_query, nil)
      cont = Keyword.get(opts, :cont, nil)

      raw_result =
        case cont do
          :end_of_table -> :end_of_table
          nil -> existing_traces_start(table_id, opts)
          _cont -> existing_traces_continuation(opts)
        end

      raw_result
      |> normalize_entries()
      |> filter_by_search(search_query)
      |> format_response()
    end

    @impl true
    def clear!(table_id, node_id \\ nil)

    def clear!(table_id, %CID{} = node_id) do
      table_id
      |> ets_table()
      |> :ets.match_delete({:_, %{cid: node_id}})
    end

    def clear!(table_id, node_id) when is_pid(node_id) do
      table_id
      |> ets_table()
      |> :ets.match_delete({:_, %{pid: node_id, cid: nil}})
    end

    def clear!(table_id, nil) do
      table_id
      |> ets_table()
      |> :ets.delete_all_objects()
    end

    @impl true
    def get_table(pid) do
      ets_table(pid)
    end

    @impl true
    def delete_table!(ref) when is_reference(ref) do
      @processes_table_name
      |> :ets.select_delete([{{:_, ref}, [], [true]}])
      |> case do
        0 -> false
        _ -> :ets.delete(ref)
      end
    end

    def delete_table!(pid) when is_pid(pid) do
      @processes_table_name
      |> :ets.lookup(pid)
      |> case do
        [] ->
          false

        [{_, ref}] ->
          :ets.delete(@processes_table_name, pid)
          :ets.delete(ref)
      end
    end

    @impl true
    def get_all_tables() do
      :ets.tab2list(@processes_table_name)
    end

    # Converts ETS entries of {key, Trace} to list of Trace structs
    defp normalize_entries(:end_of_table), do: :end_of_table
    defp normalize_entries(:"$end_of_table"), do: :end_of_table

    defp normalize_entries({entries, cont}) do
      traces = Enum.map(entries, &elem(&1, 1))
      {traces, cont}
    end

    # Applies simple case-sensitive substring search on entire struct
    @spec filter_by_search(
            {[Trace.t()], ets_continuation()} | :end_of_table,
            String.t() | nil
          ) :: {[Trace.t()], ets_continuation()} | :end_of_table
    defp filter_by_search(:end_of_table, _phrase), do: :end_of_table
    defp filter_by_search({traces, cont}, nil), do: {traces, cont}

    defp filter_by_search({traces, cont}, phrase) do
      down = String.downcase(phrase)

      filtered =
        traces
        |> Enum.filter(fn trace ->
          trace
          |> inspect()
          |> String.downcase()
          |> String.contains?(down)
        end)

      {filtered, cont}
    end

    # Formats the continuation token and handles end-of-table marker.
    @spec format_response({[Trace.t()], ets_continuation()} | :end_of_table) ::
            {[Trace.t()], ets_continuation()} | :end_of_table
    defp format_response(:end_of_table), do: :end_of_table
    defp format_response({traces, :"$end_of_table"}), do: {traces, :end_of_table}
    defp format_response({traces, cont}), do: {traces, cont}

    @spec existing_traces_start(ets_table_id(), Keyword.t()) ::
            {[ets_elem()], ets_continuation()} | :"$end_of_table"
    defp existing_traces_start(table_id, opts) do
      limit = Keyword.get(opts, :limit, @default_limit)

      functions =
        Keyword.get(opts, :functions, [])
        |> Enum.map(&String.split(&1, "/"))
        |> Enum.map(fn [function, arity] ->
          {String.to_existing_atom(function), String.to_integer(arity)}
        end)

      execution_times = Keyword.get(opts, :execution_times, %{})
      node_id = Keyword.get(opts, :node_id)

      if limit < 1 do
        raise ArgumentError, "limit must be >= 1"
      end

      match_spec = match_spec(node_id, functions, execution_times)

      table_id
      |> ets_table()
      |> :ets.select(match_spec, limit)
    end

    @spec existing_traces_continuation(Keyword.t()) ::
            {[ets_elem()], ets_continuation()} | :"$end_of_table"
    defp existing_traces_continuation(opts) do
      cont = Keyword.get(opts, :cont, nil)

      :ets.select(cont)
    end

    defp match_spec(node_id, functions, execution_times) when is_pid(node_id) do
      [
        {{:_, %{function: :"$1", execution_time: :"$2", arity: :"$3", pid: node_id, cid: nil}},
         to_spec(functions, execution_times), [:"$_"]}
      ]
    end

    defp match_spec(%CID{} = node_id, functions, execution_times) do
      [
        {{:_, %{function: :"$1", execution_time: :"$2", arity: :"$3", cid: node_id}},
         to_spec(functions, execution_times), [:"$_"]}
      ]
    end

    defp match_spec(nil, functions, execution_times) do
      [
        {{:_, %{function: :"$1", execution_time: :"$2", arity: :"$3"}},
         to_spec(functions, execution_times), [:"$_"]}
      ]
    end

    defp to_spec(functions, []) do
      [{:andalso, functions_to_spec(functions), {:"/=", :"$2", nil}}]
    end

    defp to_spec(functions, execution_times) do
      [
        {:andalso,
         {:andalso, functions_to_spec(functions), execution_times_to_spec(execution_times)},
         {:"/=", :"$2", nil}}
      ]
    end

    defp functions_to_spec([]), do: false

    defp functions_to_spec([{single_function, arity}]) do
      {:andalso, {:"=:=", :"$1", single_function}, {:"=:=", :"$3", arity}}
    end

    defp functions_to_spec([first, second | rest]) do
      initial_orelse =
        {:orelse, functions_to_spec([first]), functions_to_spec([second])}

      result =
        Enum.reduce(rest, initial_orelse, fn x, acc ->
          {:orelse, acc, functions_to_spec([x])}
        end)

      {:andalso, result, {:"/=", :"$2", nil}}
    end

    defp execution_times_to_spec(execution_times) do
      min_time = Map.get(execution_times, "exec_time_min", 0)
      max_time = Map.get(execution_times, "exec_time_max", :infinity)
      {:andalso, {:>=, :"$2", min_time}, {:"=<", :"$2", max_time}}
    end

    @spec ets_table(table_identifier()) :: :ets.table()
    defp ets_table(pid_or_ref) when is_reference(pid_or_ref), do: pid_or_ref

    defp ets_table(pid) when is_pid(pid) do
      case :ets.lookup(@processes_table_name, pid) do
        [] ->
          ref = :ets.new(@traces_table_name, [:ordered_set, :public])
          :ets.insert(@processes_table_name, {pid, ref})
          :ets.give_away(ref, Process.whereis(LiveDebugger.Supervisor), nil)
          ref

        [{^pid, ref}] ->
          ref
      end
    end
  end
end
