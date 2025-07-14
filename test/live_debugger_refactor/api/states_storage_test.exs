defmodule LiveDebuggerRefactor.Api.StatesStorageTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.Fakes
  alias LiveDebuggerRefactor.Structs.LvState
  alias LiveDebuggerRefactor.API.StatesStorage.Impl, as: StateStorageImpl

  @table_name :lvdbg_states

  describe "init/0" do
    test "creates proper table" do
      assert :ok = StateStorageImpl.init()

      ref = :ets.whereis(@table_name)
      assert is_reference(ref)
    end

    test "clears table if already exists" do
      :ets.new(@table_name, [:public, :ordered_set, :named_table])
      :ets.insert(@table_name, {1, :element})

      assert :ok = StateStorageImpl.init()

      assert [] = :ets.select(@table_name, [])
    end
  end

  describe "when table is initialized " do
    setup do
      :ets.new(@table_name, [:public, :ordered_set, :named_table])
      :ok
    end

    test "save!/2 saves element with pid as key" do
      pid = :c.pid(0, 1, 0)

      state = %LvState{
        pid: pid,
        socket: Fakes.socket(),
        components: Fakes.live_components()
      }

      assert true == StateStorageImpl.save!(state)

      assert [{^pid, ^state}] = :ets.lookup(@table_name, pid)
    end

    test "get!/1 returns saved state" do
      pid = :c.pid(0, 2, 0)

      state = %LvState{
        pid: pid,
        socket: Fakes.socket(),
        components: Fakes.live_components()
      }

      :ets.insert(@table_name, {pid, state})

      assert ^state = StateStorageImpl.get!(pid)
    end

    test "get!/1 returns nil if state not saved" do
      pid = :c.pid(0, 1, 0)

      assert nil == StateStorageImpl.get!(pid)
    end
  end
end
