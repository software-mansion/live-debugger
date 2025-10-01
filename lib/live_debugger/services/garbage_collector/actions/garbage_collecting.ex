defmodule LiveDebugger.Services.GarbageCollector.Actions.GarbageCollecting do
  @moduledoc """
  Actions for LiveDebugger.Services.GarbageCollector.
  """

  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.API.TracesStorage
  alias LiveDebugger.Services.GarbageCollector.GenServers.GarbageCollector

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.GarbageCollector.Events.TableTrimmed
  alias LiveDebugger.Services.GarbageCollector.Events.TableDeleted

  @megabyte_unit 1_048_576
  @watched_table_size 50 * @megabyte_unit
  @non_watched_table_size 5 * @megabyte_unit

  @doc """
  Performs garbage collection on traces based on `to_remove`, `watched_pids`, and `alive_pids` sets.
  Returns a set of PIDs marked for removal in next cycle.
  """
  @spec garbage_collect_traces!(GarbageCollector.state(), MapSet.t(pid()), MapSet.t(pid())) ::
          to_remove :: MapSet.t(pid())
  def garbage_collect_traces!(%{to_remove: to_remove}, watched_pids, alive_pids) do
    TracesStorage.get_all_tables()
    |> Enum.map(fn {pid, table} ->
      result =
        cond do
          MapSet.member?(watched_pids, pid) -> maybe_trim_traces_table!(table, :watched)
          MapSet.member?(alive_pids, pid) -> maybe_trim_traces_table!(table, :non_watched)
          MapSet.member?(to_remove, pid) -> delete_traces_table!(table)
          true -> :to_remove
        end

      {pid, result}
    end)
    |> aggregate_results()
  end

  @doc """
  Performs garbage collection on states based on `to_remove`, `watched_pids`, and `alive_pids` sets.
  Returns a set of PIDs marked for removal in next cycle.
  """
  @spec garbage_collect_states!(GarbageCollector.state(), MapSet.t(pid()), MapSet.t(pid())) ::
          to_remove :: MapSet.t(pid())
  def garbage_collect_states!(%{to_remove: to_remove}, watched_pids, alive_pids) do
    StatesStorage.get_all_states()
    |> Enum.map(fn {pid, _} ->
      result =
        cond do
          watched_or_alive?(pid, watched_pids, alive_pids) -> :keep
          MapSet.member?(to_remove, pid) -> delete_state!(pid)
          true -> :to_remove
        end

      {pid, result}
    end)
    |> aggregate_results()
  end

  defp watched_or_alive?(pid, watched_pids, alive_pids) do
    MapSet.member?(watched_pids, pid) or MapSet.member?(alive_pids, pid)
  end

  defp maybe_trim_traces_table!(table, type) when type in [:watched, :non_watched] do
    size = TracesStorage.table_size(table)
    max_size = max_table_size(type)

    if size > max_size do
      TracesStorage.trim_table!(table, max_size)
      Bus.broadcast_event!(%TableTrimmed{})
    end

    :keep
  end

  defp delete_traces_table!(table) do
    TracesStorage.delete_table!(table)
    Bus.broadcast_event!(%TableDeleted{})
    :removed
  end

  defp delete_state!(pid) do
    StatesStorage.delete!(pid)
    Bus.broadcast_event!(%TableTrimmed{})
    :removed
  end

  defp aggregate_results(gc_result) do
    gc_result
    |> Enum.reduce(MapSet.new(), fn
      {pid, :to_remove}, acc -> MapSet.put(acc, pid)
      _, acc -> acc
    end)
  end

  defp max_table_size(:watched), do: @watched_table_size
  defp max_table_size(:non_watched), do: @non_watched_table_size
end
