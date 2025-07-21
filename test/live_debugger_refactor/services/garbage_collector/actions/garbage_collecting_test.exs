defmodule LiveDebuggerRefactor.Services.GarbageCollector.Actions.GarbageCollectingTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Services.GarbageCollector.Actions.GarbageCollecting,
    as: GarbageCollectingActions

  alias LiveDebuggerRefactor.MockAPITracesStorage

  alias LiveDebuggerRefactor.MockBus
  alias LiveDebuggerRefactor.Services.GarbageCollector.Events.TableTrimmed
  alias LiveDebuggerRefactor.Services.GarbageCollector.Events.TableDeleted

  @megabyte_unit 1_048_576

  describe "garbage_collect_traces!/0" do
    test "collects garbage if max size exceeded" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([pid1])
      alive_pids = MapSet.new([pid2])
      table1 = make_ref()
      table2 = make_ref()

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}, {pid2, table2}] end)
      |> expect(:table_size, fn ^table1 -> 12 * @megabyte_unit end)
      |> expect(:table_size, fn ^table2 -> 1.1 * @megabyte_unit end)

      max_table_size = 10 * @megabyte_unit

      MockAPITracesStorage
      |> expect(:trim_table!, fn ^table1, ^max_table_size -> :ok end)
      |> expect(:trim_table!, fn ^table2, @megabyte_unit -> :ok end)

      MockBus
      |> Mox.expect(:broadcast_event!, 2, fn %TableTrimmed{} -> :ok end)

      assert true == GarbageCollectingActions.garbage_collect_traces!(watched_pids, alive_pids)
    end

    test "does not collect garbage if max size not exceeded" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([pid1])
      alive_pids = MapSet.new([pid2])
      table1 = make_ref()
      table2 = make_ref()

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}, {pid2, table2}] end)
      |> expect(:table_size, fn ^table1 -> 5 * @megabyte_unit end)
      |> expect(:table_size, fn ^table2 -> 0.5 * @megabyte_unit end)

      MockBus
      |> Mox.deny(:broadcast_event!, 2)

      assert false == GarbageCollectingActions.garbage_collect_traces!(watched_pids, alive_pids)
    end

    test "deletes table if not watched and no alive" do
      watched_pids = MapSet.new()
      alive_pids = MapSet.new()
      pid1 = :c.pid(0, 11, 0)
      table1 = make_ref()

      expect(MockAPITracesStorage, :get_all_tables, fn -> [{pid1, table1}] end)
      expect(MockAPITracesStorage, :delete_table!, fn ^table1 -> :ok end)
      expect(MockBus, :broadcast_event!, 1, fn %TableDeleted{} -> :ok end)

      assert true == GarbageCollectingActions.garbage_collect_traces!(watched_pids, alive_pids)
    end
  end
end
