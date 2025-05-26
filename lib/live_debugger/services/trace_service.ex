defmodule LiveDebugger.Services.TraceService do
  @moduledoc """
  This module is responsible for accessing traces from ETS.
  It uses calls to `EtsTableServer` to get proper table reference.
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.CommonTypes
  alias LiveDebugger.GenServers.EtsTableServer
  alias Phoenix.LiveComponent.CID

  @default_limit 100

  @type ets_elem() :: {integer(), Trace.t()}
  @type ets_continuation :: term()
  @typedoc """
  Pid is used to store mapping to table references.
  It identifies ETS tables managed by EtsTableServer.
  """
  @type ets_table_id() :: pid()

  @doc """
  Inserts a new trace into the ETS table.
  """
  @spec insert(Trace.t()) :: true
  def insert(%Trace{pid: pid, id: id} = trace) do
    pid
    |> ets_table()
    |> :ets.insert({id, trace})
  end

  @doc """
  Gets a trace of process from the ETS table by `id`.
  """
  @spec get(pid :: ets_table_id(), id :: integer()) :: Trace.t() | nil
  def get(pid, id) when is_pid(pid) and is_integer(id) do
    pid
    |> ets_table()
    |> :ets.lookup(id)
    |> case do
      [] -> nil
      [{_id, trace}] -> trace
    end
  end

  @doc """
  Returns existing traces of a process for the table with optional filters.

  ## Options
    * `:node_id` - PID or CID to filter traces by
    * `:limit` - Maximum number of traces to return (default: 100)
    * `:cont` - Used to get next page of items in the following queries
    * `:functions` - List of function names to filter traces by
  """
  @spec existing_traces(pid :: ets_table_id(), opts :: keyword()) ::
          {[Trace.t()], ets_continuation()} | :end_of_table
  def existing_traces(pid, opts \\ []) when is_pid(pid) do
    opts
    |> Keyword.get(:cont, nil)
    |> case do
      :end_of_table -> :end_of_table
      nil -> existing_traces_start(pid, opts)
      _cont -> existing_traces_continuation(opts)
    end
    |> case do
      {entries, :"$end_of_table"} ->
        {Enum.map(entries, &elem(&1, 1)), :end_of_table}

      {entries, new_cont} ->
        {Enum.map(entries, &elem(&1, 1)), new_cont}

      _ ->
        :end_of_table
    end
  end

  @doc """
  Deletes traces for LiveView or LiveComponent for given pid.

  * `node_id` - PID or CID which identifies node
  """
  @spec clear_traces(pid :: ets_table_id(), node_id :: pid() | CommonTypes.cid()) :: true
  def clear_traces(pid, %CID{} = node_id) when is_pid(pid) do
    pid
    |> ets_table()
    |> :ets.match_delete({:_, %{cid: node_id}})
  end

  def clear_traces(pid, node_id) when is_pid(pid) and is_pid(node_id) do
    pid
    |> ets_table()
    |> :ets.match_delete({:_, %{pid: node_id, cid: nil}})
  end

  @spec existing_traces_start(ets_table_id(), Keyword.t()) ::
          {[ets_elem()], ets_continuation()} | :"$end_of_table"
  defp existing_traces_start(table_id, opts) do
    limit = Keyword.get(opts, :limit, @default_limit)
    functions = Keyword.get(opts, :functions, [])
    execution_times = Keyword.get(opts, :execution_times, [])
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
      {{:_, %{function: :"$1", execution_time: :"$2", pid: node_id, cid: nil}},
       to_spec(functions, execution_times), [:"$_"]}
    ]
  end

  defp match_spec(%CID{} = node_id, functions, execution_times) do
    [
      {{:_, %{function: :"$1", execution_time: :"$2", cid: node_id}},
       to_spec(functions, execution_times), [:"$_"]}
    ]
  end

  defp match_spec(nil, functions, execution_times) do
    [
      {{:_, %{function: :"$1", execution_time: :"$2"}}, to_spec(functions, execution_times),
       [:"$_"]}
    ]
  end

  def to_spec([], []), do: [{:"/=", :"$2", nil}]

  def to_spec(functions, []) do
    [{:andalso, List.first(functions_to_spec(functions)), {:"/=", :"$2", nil}}]
  end

  def to_spec([], execution_times) do
    [{:andalso, List.first(execution_times_to_spec(execution_times)), {:"/=", :"$2", nil}}]
  end

  def to_spec(functions, execution_times) do
    [
      {:andalso,
       {:andalso, List.first(functions_to_spec(functions)),
        List.first(execution_times_to_spec(execution_times))}, {:"/=", :"$2", nil}}
    ]
  end

  def functions_to_spec([single]), do: [{:"=:=", :"$1", single}]

  def functions_to_spec([first, second | rest]) do
    initial_orelse =
      {:orelse, List.first(functions_to_spec([first])), List.first(functions_to_spec([second]))}

    result =
      Enum.reduce(rest, initial_orelse, fn x, acc ->
        {:orelse, acc, List.first(functions_to_spec([x]))}
      end)

    [{:andalso, result, {:"/=", :"$2", nil}}]
  end

  def execution_times_to_spec(execution_times) do
    min_time = Keyword.get(execution_times, :exec_time_min, 0)
    max_time = Keyword.get(execution_times, :exec_time_max, :infinity)
    [{:andalso, {:>=, :"$2", min_time}, {:"=<", :"$2", max_time}}]
  end

  @spec ets_table(pid :: ets_table_id()) :: :ets.table()
  defp ets_table(pid) when is_pid(pid) do
    EtsTableServer.table(pid)
  end
end
