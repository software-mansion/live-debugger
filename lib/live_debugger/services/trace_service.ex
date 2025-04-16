defmodule LiveDebugger.Services.TraceService do
  @moduledoc """

  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.GenServers.CallbackTracingServer
  alias Phoenix.LiveComponent.CID

  @default_limit 100

  @type ets_elem() :: {integer(), Trace.t()}
  @type ets_continuation :: term()

  @doc """
  Returns reference for accessing ETS table for given process.
  """
  @spec ets_table(pid :: pid()) :: :ets.table()
  def ets_table(pid) when is_pid(pid) do
    CallbackTracingServer.table(pid)
  end

  @spec ets_table(LvProcess.t()) :: :ets.table()
  def ets_table(%LvProcess{pid: pid}) do
    CallbackTracingServer.table(pid)
  end

  @doc """
  Inserts a new trace into the ETS table.
  """
  @spec insert(table :: :ets.table(), id :: integer(), Trace.t()) :: true
  def insert(table, id, trace) when is_integer(id) do
    :ets.insert(table, {id, trace})
  end

  @doc """
  Gets a trace from the ETS table by its id.
  """
  @spec get(table :: :ets.table(), id :: integer()) :: Trace.t() | nil
  def get(table, id) when is_integer(id) do
    table
    |> :ets.lookup(id)
    |> case do
      [] -> nil
      [{_id, trace}] -> trace
    end
  end

  @doc """
  Returns existing traces for the given table id with optional filters.

  ## Options
    * `:node_id` - PID or CID to filter traces by
    * `:limit` - Maximum number of traces to return (default: 100)
    * `:cont` - Used to get next page of items in the following queries
    * `:functions` - List of function names to filter traces by
  """
  @spec existing_traces(table :: :ets.table(), opts :: keyword()) ::
          {[Trace.t()], ets_continuation()} | :end_of_table
  def existing_traces(table, opts \\ []) do
    opts
    |> Keyword.get(:cont, nil)
    |> case do
      :end_of_table -> :end_of_table
      nil -> existing_traces_start(table, opts)
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
  Deletes all traces for the given table id and CID or PID.
  """
  @spec clear_traces(table :: :ets.table(), pid() | CommonTypes.cid()) :: true
  def clear_traces(table, %CID{} = cid) do
    :ets.match_delete(table, {:_, %{cid: cid}})
  end

  def clear_traces(table, pid) when is_pid(pid) do
    :ets.match_delete(table, {:_, %{pid: pid, cid: nil}})
  end

  @spec existing_traces_start(:ets.table(), Keyword.t()) ::
          {[ets_elem()], ets_continuation()} | :"$end_of_table"
  defp existing_traces_start(table, opts) do
    limit = Keyword.get(opts, :limit, @default_limit)
    functions = Keyword.get(opts, :functions, [])
    node_id = Keyword.get(opts, :node_id)

    if limit < 1 do
      raise ArgumentError, "limit must be >= 1"
    end

    match_spec = match_spec(node_id, functions)

    :ets.select(table, match_spec, limit)
  end

  @spec existing_traces_continuation(Keyword.t()) ::
          {[ets_elem()], ets_continuation()} | :"$end_of_table"
  defp existing_traces_continuation(opts) do
    cont = Keyword.get(opts, :cont, nil)

    :ets.select(cont)
  end

  defp match_spec(node_id, functions) when is_pid(node_id) do
    [
      {{:_, %{function: :"$1", pid: node_id, cid: nil}}, to_spec(functions), [:"$_"]}
    ]
  end

  defp match_spec(%CID{} = node_id, functions) do
    [{{:_, %{function: :"$1", cid: node_id}}, to_spec(functions), [:"$_"]}]
  end

  defp match_spec(nil, functions) do
    [{{:_, %{function: :"$1"}}, to_spec(functions), [:"$_"]}]
  end

  def to_spec([]), do: []

  def to_spec([single]), do: [{:"=:=", :"$1", single}]

  def to_spec([first, second | rest]) do
    initial_orelse = {:orelse, List.first(to_spec([first])), List.first(to_spec([second]))}

    result =
      Enum.reduce(rest, initial_orelse, fn x, acc ->
        {:orelse, acc, List.first(to_spec([x]))}
      end)

    [result]
  end
end
