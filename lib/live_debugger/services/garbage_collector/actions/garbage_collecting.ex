defmodule LiveDebugger.Services.GarbageCollector.Actions.GarbageCollecting do
  @moduledoc """
  Actions for LiveDebugger.Services.GarbageCollector.
  """

  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.API.TracesStorage

  alias LiveDebugger.Services.GarbageCollector.Utils,
    as: GarbageCollectorUtils

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.GarbageCollector.Events.TableTrimmed
  alias LiveDebugger.Services.GarbageCollector.Events.TableDeleted

  @spec garbage_collect_traces!(MapSet.t(pid()), MapSet.t(pid())) :: boolean()
  def garbage_collect_traces!(watched_pids, alive_pids) do
    TracesStorage.get_all_tables()
    |> Enum.reduce(false, fn {pid, table}, acc ->
      result =
        cond do
          MapSet.member?(watched_pids, pid) -> maybe_trim_traces_table!(table, :watched)
          MapSet.member?(alive_pids, pid) -> maybe_trim_traces_table!(table, :non_watched)
          true -> delete_traces_table!(table)
        end

      acc or result
    end)
  end

  @spec garbage_collect_states!(MapSet.t(pid()), MapSet.t(pid())) :: boolean()
  def garbage_collect_states!(watched_pids, alive_pids) do
    StatesStorage.get_all_states()
    |> Enum.reduce(false, fn {pid, _}, acc ->
      result =
        if MapSet.member?(watched_pids, pid) or MapSet.member?(alive_pids, pid) do
          false
        else
          delete_state!(pid)
        end

      acc or result
    end)
  end

  defp maybe_trim_traces_table!(table, type) when type in [:watched, :non_watched] do
    size = TracesStorage.table_size(table)
    max_size = GarbageCollectorUtils.max_table_size(type)

    if size > max_size do
      TracesStorage.trim_table!(table, max_size)
      Bus.broadcast_event!(%TableTrimmed{})
      true
    else
      false
    end
  end

  defp delete_traces_table!(table) do
    TracesStorage.delete_table!(table)
    Bus.broadcast_event!(%TableDeleted{})
    true
  end

  defp delete_state!(pid) do
    StatesStorage.delete!(pid)
    Bus.broadcast_event!(%TableTrimmed{})
    true
  end
end
