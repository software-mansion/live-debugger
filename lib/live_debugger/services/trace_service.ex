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
  Returns existing traces for the given table id and CID or PID.
  It returns up to `limit` traces.
  """
  @spec existing_traces(atom(), pid() | CommonTypes.cid(), pos_integer()) :: [Trace.t()]
  def existing_traces(table_id, id, limit) when limit >= 1 do
    matcher =
      cond do
        is_pid(id) ->
          {:_, %{pid: id, cid: nil}}

        match?(%CID{}, id) ->
          {:_, %{cid: id}}

        true ->
          raise ArgumentError, "id must be either PID or CID"
      end

    table_id
    |> maybe_init_ets()
    |> :ets.match_object(matcher, limit)
    |> case do
      {entries, _cont} ->
        Enum.map(entries, &elem(&1, 1))

      _ ->
        []
    end
  end

  @doc """
  Returns all existing traces for the given table id.
  """
  @spec existing_traces(atom()) :: [Trace.t()]
  def existing_traces(table_id) do
    table_id |> maybe_init_ets() |> :ets.tab2list() |> Enum.map(&elem(&1, 1))
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
end
