defmodule LiveDebugger.Services.TraceService do
  @moduledoc """
  This module provides functions that manages traces in the debugged application via ETS.
  Created table is an ordered_set with non-positive integer keys.
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Structs.LvProcess
  alias Phoenix.LiveComponent.CID

  @id_prefix "lvdbg-traces"
  @default_limit 100

  @doc """
  Returns the ETS table id for the given socket id.
  """
  @spec ets_table_id(pid(), String.t()) :: :ets.table()
  def ets_table_id(transport_pid, socket_id) do
    String.to_atom("#{@id_prefix}-#{inspect(transport_pid)}-#{socket_id}")
  end

  @spec ets_table_id(LvProcess.t()) :: :ets.table()
  def ets_table_id(%LvProcess{transport_pid: transport_pid, socket_id: socket_id}) do
    ets_table_id(transport_pid, socket_id)
  end

  @doc """
  Initializes an ETS table with the given id if it doesn't exist.
  """
  @spec maybe_init_ets(:ets.table()) :: :ets.table()
  def maybe_init_ets(ets_table_id) do
    if :ets.whereis(ets_table_id) == :undefined do
      :ets.new(ets_table_id, [:ordered_set, :public, :named_table])
    else
      ets_table_id
    end
  end

  @doc """
  Inserts a new trace into the ETS table.
  """
  @spec insert(:ets.table(), integer(), Trace.t()) :: true
  def insert(table_id, id, trace) do
    table_id
    |> maybe_init_ets()
    |> :ets.insert({id, trace})
  end

  @doc """
  Gets a trace from the ETS table by its id.
  """
  @spec get(:ets.table(), integer()) :: Trace.t() | nil
  def get(table_id, id) do
    table_id
    |> maybe_init_ets()
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
  @spec existing_traces(atom(), keyword()) :: {[Trace.t()], term()} | :"$end_of_table"
  def existing_traces(table_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, @default_limit)
    functions = Keyword.get(opts, :functions, [])
    cont = Keyword.get(opts, :cont, nil)
    node_id = Keyword.get(opts, :node_id)

    if limit < 1 do
      raise ArgumentError, "limit must be >= 1"
    end

    if cont == nil do
      match_spec = match_spec(node_id, functions)

      table_id
      |> maybe_init_ets()
      |> :ets.select(match_spec, limit)
      |> case do
        {entries, new_cont} ->
          {Enum.map(entries, &elem(&1, 1)), new_cont}

        :"$end_of_table" ->
          :"$end_of_table"
      end
    else
      cont
      |> :ets.select()
      |> case do
        {entries, new_cont} ->
          {Enum.map(entries, &elem(&1, 1)), new_cont}

        :"$end_of_table" ->
          :"$end_of_table"
      end
    end
  end

  @doc """
  Deletes all traces for the given table id and CID or PID.
  """
  @spec clear_traces(atom(), pid() | CommonTypes.cid()) :: true
  def clear_traces(table_id, %CID{} = cid) do
    table_id
    |> maybe_init_ets()
    |> :ets.match_delete({:_, %{cid: cid}})
  end

  def clear_traces(table_id, pid) when is_pid(pid) do
    table_id
    |> maybe_init_ets()
    |> :ets.match_delete({:_, %{pid: pid, cid: nil}})
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
