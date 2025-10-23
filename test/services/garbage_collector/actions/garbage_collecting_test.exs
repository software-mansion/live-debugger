defmodule LiveDebugger.Services.GarbageCollector.Actions.GarbageCollectingTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.GarbageCollector.Actions.GarbageCollecting,
    as: GarbageCollectingActions

  alias LiveDebugger.MockAPITracesStorage
  alias LiveDebugger.MockAPIStatesStorage

  alias LiveDebugger.MockBus
  alias LiveDebugger.Services.GarbageCollector.Events.TableTrimmed
  alias LiveDebugger.Services.GarbageCollector.Events.TableDeleted

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
      state = %{to_remove: %{}}

      max_table_size_watched = 50 * @megabyte_unit
      max_table_size_non_watched = 5 * @megabyte_unit

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}, {pid2, table2}] end)
      |> expect(:table_size, fn ^table1 -> max_table_size_watched + @megabyte_unit end)
      |> expect(:table_size, fn ^table2 -> max_table_size_non_watched + @megabyte_unit end)
      |> expect(:trim_table!, fn ^table1, ^max_table_size_watched -> :ok end)
      |> expect(:trim_table!, fn ^table2, ^max_table_size_non_watched -> :ok end)

      MockBus
      |> expect(:broadcast_event!, 2, fn %TableTrimmed{} -> :ok end)

      assert %{} ==
               GarbageCollectingActions.garbage_collect_traces!(state, watched_pids, alive_pids)
    end

    test "does not collect garbage if max size not exceeded" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([pid1])
      alive_pids = MapSet.new([pid2])
      table1 = make_ref()
      table2 = make_ref()
      state = %{to_remove: %{}}

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}, {pid2, table2}] end)
      |> expect(:table_size, fn ^table1 -> 5 * @megabyte_unit end)
      |> expect(:table_size, fn ^table2 -> 0.5 * @megabyte_unit end)
      |> deny(:trim_table!, 2)

      MockBus
      |> deny(:broadcast_event!, 2)

      assert %{} ==
               GarbageCollectingActions.garbage_collect_traces!(state, watched_pids, alive_pids)
    end

    test "marks for removal if not watched and not alive" do
      watched_pids = MapSet.new()
      alive_pids = MapSet.new()
      pid1 = :c.pid(0, 11, 0)
      table1 = make_ref()
      state = %{to_remove: %{}}

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}] end)
      |> deny(:delete_table!, 1)

      assert %{pid1 => 2} ==
               GarbageCollectingActions.garbage_collect_traces!(state, watched_pids, alive_pids)
    end

    test "decreaments removal counter if not watched and not alive" do
      pid1 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([:c.pid(0, 11, 0)])
      alive_pids = MapSet.new([:c.pid(0, 13, 0)])
      table1 = make_ref()
      state = %{to_remove: %{pid1 => 2}}

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}] end)
      |> deny(:delete_table!, 1)

      MockBus
      |> deny(:broadcast_event!, 1)

      assert %{pid1 => 1} ==
               GarbageCollectingActions.garbage_collect_traces!(state, watched_pids, alive_pids)
    end

    test "deletes table if not watched, not alive and marked to remove" do
      watched_pids = MapSet.new()
      alive_pids = MapSet.new()
      pid1 = :c.pid(0, 11, 0)
      table1 = make_ref()
      state = %{to_remove: %{pid1 => 0}}

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}] end)
      |> expect(:delete_table!, fn ^table1 -> :ok end)

      MockBus
      |> expect(:broadcast_event!, fn %TableDeleted{} -> :ok end)

      assert %{} ==
               GarbageCollectingActions.garbage_collect_traces!(state, watched_pids, alive_pids)
    end
  end

  describe "garbage_collect_states!/1" do
    test "marks for removal if not watched and not alive" do
      pid1 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([:c.pid(0, 11, 0)])
      alive_pids = MapSet.new([:c.pid(0, 13, 0)])
      state = %{to_remove: %{}}

      MockAPIStatesStorage
      |> expect(:get_all_states, fn -> [{pid1, :some_state}] end)
      |> deny(:delete!, 1)

      assert %{pid1 => 2} ==
               GarbageCollectingActions.garbage_collect_states!(state, watched_pids, alive_pids)
    end

    test "decreaments removal counter if not watched and not alive" do
      pid1 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([:c.pid(0, 11, 0)])
      alive_pids = MapSet.new([:c.pid(0, 13, 0)])
      state = %{to_remove: %{pid1 => 2}}

      MockAPIStatesStorage
      |> expect(:get_all_states, 2, fn -> [{pid1, :some_state}] end)
      |> deny(:delete!, 1)

      MockBus
      |> deny(:broadcast_event!, 1)

      assert %{pid1 => 1} ==
               GarbageCollectingActions.garbage_collect_states!(state, watched_pids, alive_pids)

      state = %{to_remove: %{pid1 => 1}}

      assert %{pid1 => 0} ==
               GarbageCollectingActions.garbage_collect_states!(state, watched_pids, alive_pids)
    end

    test "deletes states if not watched, not alive and marked for removal " do
      pid1 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([:c.pid(0, 11, 0)])
      alive_pids = MapSet.new([:c.pid(0, 13, 0)])
      state = %{to_remove: %{pid1 => 0}}

      MockAPIStatesStorage
      |> expect(:get_all_states, fn -> [{pid1, :some_state}] end)
      |> expect(:delete!, fn ^pid1 -> :ok end)

      MockBus
      |> expect(:broadcast_event!, fn %TableTrimmed{} -> :ok end)

      assert %{} ==
               GarbageCollectingActions.garbage_collect_states!(state, watched_pids, alive_pids)
    end

    test "do nothing if pids are watched or alive" do
      pid1 = :c.pid(0, 12, 0)
      pid2 = :c.pid(0, 13, 0)
      watched_pids = MapSet.new([pid1])
      alive_pids = MapSet.new([pid2])
      state = %{to_remove: %{}}

      MockAPIStatesStorage
      |> expect(:get_all_states, fn -> [{pid1, :some_state}, {pid2, :some_other_state}] end)
      |> deny(:delete!, 1)

      MockBus
      |> deny(:broadcast_event!, 1)

      assert %{} ==
               GarbageCollectingActions.garbage_collect_states!(state, watched_pids, alive_pids)
    end
  end
end
