defmodule LiveDebugger.Services.TraceService do
  @moduledoc """
  This module provides functions that manages traces in the debugged application via ETS.
  Created table is an ordered_set with non-positive integer keys.
  """

  require Logger

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.CommonTypes
  alias Phoenix.LiveComponent.CID

  @id_prefix "lvdbg-traces"

  @doc """
  Returns the ETS table id for the given socket id.
  """
  @spec ets_table_id(socket_id :: String.t()) :: :ets.table()
  def ets_table_id(socket_id), do: String.to_atom("#{@id_prefix}-#{socket_id}")

  @doc """
  Initializes an ETS table with the given id if it doesn't exist.
  """
  @spec maybe_init_ets(ets_table_id :: :ets.table()) :: :ets.table()
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
  @spec insert(trace :: Trace.t()) :: true
  def insert(%{socket_id: socket_id, id: id} = trace) when is_binary(socket_id) do
    socket_id
    |> ets_table_id()
    |> maybe_init_ets()
    |> :ets.insert({id, trace})
  end

  @doc """
  Returns all existing traces for the given table id and CID or PID.
  """
  @spec existing_traces(table_id :: atom(), node_id :: pid() | CommonTypes.cid()) :: [Trace.t()]
  def existing_traces(table_id, %CID{} = node_id) do
    :ets.match_object(table_id, {:_, %{cid: node_id}}) |> Enum.map(&elem(&1, 1))
  end

  def existing_traces(table_id, node_id) when is_pid(node_id) do
    :ets.match_object(table_id, {:_, %{pid: node_id, cid: nil}}) |> Enum.map(&elem(&1, 1))
  end

  @doc """
  Returns all existing traces for the given table id.
  """
  @spec existing_traces(table_id :: atom()) :: [Trace.t()]
  def existing_traces(table_id) do
    table_id |> :ets.tab2list() |> Enum.map(&elem(&1, 1))
  end

  @doc """
  Deletes all traces for the given table id and CID or PID.
  """
  @spec clear_traces(table_id :: atom(), node_id :: pid() | CommonTypes.cid()) :: true
  def clear_traces(table_id, %CID{} = node_id) do
    :ets.match_delete(table_id, {:_, %{cid: node_id}})
  end

  def clear_traces(table_id, node_id) when is_pid(node_id) do
    :ets.match_delete(table_id, {:_, %{pid: node_id, cid: nil}})
  end
end
