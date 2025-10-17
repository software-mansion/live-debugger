defmodule LiveDebugger.Services.GarbageCollector.Actions.GarbageCollectingTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.MockAPIStatesStorage
  alias LiveDebugger.MockAPITracesStorage
  alias LiveDebugger.MockBus

  alias LiveDebugger.Services.GarbageCollector.Actions.GarbageCollecting,
    as: GarbageCollectingActions

  alias LiveDebugger.Services.GarbageCollector.Events.TableDeleted
  alias LiveDebugger.Services.GarbageCollector.Events.TableTrimmed

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
      state = %{to_remove: MapSet.new()}

      max_table_size_watched = 50 * @megabyte_unit
      max_table_size_non_watched = 5 * @megabyte_unit

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}, {pid2, table2}] end)
      |> expect(:table_size, fn ^table1 -> max_table_size_watched + @megabyte_unit end)
      |> expect(:table_size, fn ^table2 -> max_table_size_non_watched + @megabyte_unit end)
      |> expect(:trim_table!, fn ^table1, ^max_table_size_watched -> :ok end)
      |> expect(:trim_table!, fn ^table2, ^max_table_size_non_watched -> :ok end)

      expect(MockBus, :broadcast_event!, 2, fn %TableTrimmed{} -> :ok end)

      assert MapSet.new() ==
               GarbageCollectingActions.garbage_collect_traces!(state, watched_pids, alive_pids)
    end

    test "does not collect garbage if max size not exceeded" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([pid1])
      alive_pids = MapSet.new([pid2])
      table1 = make_ref()
      table2 = make_ref()
      state = %{to_remove: MapSet.new()}

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}, {pid2, table2}] end)
      |> expect(:table_size, fn ^table1 -> 5 * @megabyte_unit end)
      |> expect(:table_size, fn ^table2 -> 0.5 * @megabyte_unit end)
      |> deny(:trim_table!, 2)

      deny(MockBus, :broadcast_event!, 2)

      assert MapSet.new() ==
               GarbageCollectingActions.garbage_collect_traces!(state, watched_pids, alive_pids)
    end

    test "marks for removal if not watched and not alive" do
      watched_pids = MapSet.new()
      alive_pids = MapSet.new()
      pid1 = :c.pid(0, 11, 0)
      table1 = make_ref()
      state = %{to_remove: MapSet.new([])}

      expect(MockAPITracesStorage, :get_all_tables, fn -> [{pid1, table1}] end)

      assert MapSet.new([pid1]) ==
               GarbageCollectingActions.garbage_collect_traces!(state, watched_pids, alive_pids)
    end

    test "deletes table if not watched, not alive and marked to remove" do
      watched_pids = MapSet.new()
      alive_pids = MapSet.new()
      pid1 = :c.pid(0, 11, 0)
      table1 = make_ref()
      state = %{to_remove: MapSet.new([pid1])}

      expect(MockAPITracesStorage, :get_all_tables, fn -> [{pid1, table1}] end)
      expect(MockAPITracesStorage, :delete_table!, fn ^table1 -> :ok end)
      expect(MockBus, :broadcast_event!, fn %TableDeleted{} -> :ok end)

      assert MapSet.new() ==
               GarbageCollectingActions.garbage_collect_traces!(state, watched_pids, alive_pids)
    end
  end

  describe "garbage_collect_states!/1" do
    test "marks for removal if not watched and not alive" do
      pid1 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([:c.pid(0, 11, 0)])
      alive_pids = MapSet.new([:c.pid(0, 13, 0)])
      state = %{to_remove: MapSet.new()}

      expect(MockAPIStatesStorage, :get_all_states, fn -> [{pid1, :some_state}] end)

      assert MapSet.new([pid1]) ==
               GarbageCollectingActions.garbage_collect_states!(state, watched_pids, alive_pids)
    end

    test "deletes states if not watched, not alive and marked for removal " do
      pid1 = :c.pid(0, 12, 0)
      watched_pids = MapSet.new([:c.pid(0, 11, 0)])
      alive_pids = MapSet.new([:c.pid(0, 13, 0)])
      state = %{to_remove: MapSet.new([pid1])}

      MockAPIStatesStorage
      |> expect(:get_all_states, fn -> [{pid1, :some_state}] end)
      |> expect(:delete!, fn ^pid1 -> :ok end)

      expect(MockBus, :broadcast_event!, fn %TableTrimmed{} -> :ok end)

      assert MapSet.new() ==
               GarbageCollectingActions.garbage_collect_states!(state, watched_pids, alive_pids)
    end

    test "do nothing if pids are watched or alive" do
      pid1 = :c.pid(0, 12, 0)
      pid2 = :c.pid(0, 13, 0)
      watched_pids = MapSet.new([pid1])
      alive_pids = MapSet.new([pid2])
      state = %{to_remove: MapSet.new()}

      MockAPIStatesStorage
      |> expect(:get_all_states, fn -> [{pid1, :some_state}, {pid2, :some_other_state}] end)
      |> deny(:delete!, 1)

      deny(MockBus, :broadcast_event!, 1)

      assert MapSet.new() ==
               GarbageCollectingActions.garbage_collect_states!(state, watched_pids, alive_pids)
    end
  end
end
