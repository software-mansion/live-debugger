defmodule LiveDebuggerRefactor.Services.GarbageCollector.Actions.GarbageCollectingTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Services.GarbageCollector.Actions.GarbageCollecting,
    as: GarbageCollectingActions

  alias LiveDebuggerRefactor.MockAPITracesStorage
  alias LiveDebuggerRefactor.MockAPIStatesStorage

  alias LiveDebuggerRefactor.MockBus
  alias LiveDebuggerRefactor.Services.GarbageCollector.Events.TableTrimmed
  alias LiveDebuggerRefactor.Services.GarbageCollector.Events.TableDeleted

  @megabyte_unit 1_048_576

  setup :verify_on_exit!

  describe "garbage_collect_traces!/2" do
    test "collects garbage if max size exceeded" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([pid1])
      alive_pids = MapSet.new([pid2])
      table1 = make_ref()
      table2 = make_ref()

      max_table_size_watched = 20 * @megabyte_unit
      max_table_size_non_watched = 2 * @megabyte_unit

      Application.put_env(:live_debugger, :approx_table_max_size, 20)

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}, {pid2, table2}] end)
      |> expect(:table_size, fn ^table1 -> max_table_size_watched + @megabyte_unit end)
      |> expect(:table_size, fn ^table2 -> max_table_size_non_watched + @megabyte_unit end)
      |> expect(:trim_table!, fn ^table1, ^max_table_size_watched -> :ok end)
      |> expect(:trim_table!, fn ^table2, ^max_table_size_non_watched -> :ok end)

      MockBus
      |> expect(:broadcast_event!, 2, fn %TableTrimmed{} -> :ok end)

      assert true == GarbageCollectingActions.garbage_collect_traces!(watched_pids, alive_pids)
    end

    test "does not collect garbage if max size not exceeded" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([pid1])
      alive_pids = MapSet.new([pid2])
      table1 = make_ref()
      table2 = make_ref()

      Application.put_env(:live_debugger, :approx_table_max_size, 20)

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}, {pid2, table2}] end)
      |> expect(:table_size, fn ^table1 -> 5 * @megabyte_unit end)
      |> expect(:table_size, fn ^table2 -> 0.5 * @megabyte_unit end)
      |> deny(:trim_table!, 2)

      MockBus
      |> deny(:broadcast_event!, 2)

      assert false == GarbageCollectingActions.garbage_collect_traces!(watched_pids, alive_pids)
    end

    test "deletes table if not watched and no alive" do
      watched_pids = MapSet.new()
      alive_pids = MapSet.new()
      pid1 = :c.pid(0, 11, 0)
      table1 = make_ref()

      expect(MockAPITracesStorage, :get_all_tables, fn -> [{pid1, table1}] end)
      expect(MockAPITracesStorage, :delete_table!, fn ^table1 -> :ok end)
      expect(MockBus, :broadcast_event!, fn %TableDeleted{} -> :ok end)

      assert true == GarbageCollectingActions.garbage_collect_traces!(watched_pids, alive_pids)
    end
  end

  describe "garbage_collect_states!/1" do
    test "collects garbage for states if pids are not watched and not alive" do
      pid1 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([:c.pid(0, 11, 0)])
      alive_pids = MapSet.new([:c.pid(0, 13, 0)])

      MockAPIStatesStorage
      |> expect(:get_all_states, fn -> [{pid1, :some_state}] end)
      |> expect(:delete!, fn ^pid1 -> :ok end)

      MockBus
      |> expect(:broadcast_event!, fn %TableTrimmed{} -> :ok end)

      assert true == GarbageCollectingActions.garbage_collect_states!(watched_pids, alive_pids)
    end

    test "does not collect garbage for states if pids are watched or alive" do
      pid1 = :c.pid(0, 12, 0)
      pid2 = :c.pid(0, 13, 0)
      watched_pids = MapSet.new([pid1])
      alive_pids = MapSet.new([pid2])

      MockAPIStatesStorage
      |> expect(:get_all_states, fn -> [{pid1, :some_state}, {pid2, :some_other_state}] end)
      |> deny(:delete!, 1)

      MockBus
      |> deny(:broadcast_event!, 1)

      assert false == GarbageCollectingActions.garbage_collect_states!(watched_pids, alive_pids)
    end
  end
end
