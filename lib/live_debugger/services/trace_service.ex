defmodule LiveDebugger.Services.TraceService do
  @moduledoc """
  This module provides functions that manages traces in the debugged application via ETS.
  Created table is an ordered_set with non-positive integer keys.
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.CommonTypes
  alias Phoenix.LiveComponent.CID

  @id_prefix "lvdbg-traces"

  @doc """
  Returns the ETS table id for the given socket id.
  """
  @spec ets_table_id(String.t()) :: :ets.table()
  def ets_table_id(socket_id), do: String.to_atom("#{@id_prefix}-#{socket_id}")

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
  Creates the id of next tuple based on the first tuple in the ETS table.
  We need to store traces in this table in descending order.
  To achieve this table is implemented as ordered_set with non-positive integer keys.
  Because of that the element with the smallest key is the first element in the table.
  """
  @spec next_tuple_id(:ets.table()) :: integer()
  def next_tuple_id(ets_table_id) do
    ets_table_id
    |> maybe_init_ets()
    |> :ets.first()
    |> case do
      :"$end_of_table" -> 0
      last_id -> last_id - 1
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
  Returns all existing traces for the given table id and CID or PID.
  """
  @spec existing_traces(atom(), pid() | CommonTypes.cid()) :: [Trace.t()]
  def existing_traces(table_id, %CID{} = cid) do
    table_id |> maybe_init_ets() |> :ets.match_object({:_, %{cid: cid}}) |> Enum.map(&elem(&1, 1))
  end

  def existing_traces(table_id, pid) when is_pid(pid) do
    table_id
    |> maybe_init_ets()
    |> :ets.match_object({:_, %{pid: pid, cid: nil}})
    |> Enum.map(&elem(&1, 1))
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
