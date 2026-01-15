defmodule LiveDebugger.Services.CallbackTracer.Queries.Traces do
  @moduledoc """
  This module provides queries for traces.
  """

  alias LiveDebugger.API.TracesStorage

  @spec get_last_trace_id() :: integer()
  def get_last_trace_id() do
    TracesStorage.get_all_tables()
    |> Enum.map(fn {_, ref} -> :ets.first(ref) end)
    |> Enum.filter(fn id -> id != :"$end_of_table" end)
    |> case do
      [] -> 0
      ids -> Enum.min(ids)
    end
  end
end
