defmodule LiveDebugger.App.Debugger.NestedLiveViewLinks.QueriesTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.App.Debugger.NestedLiveViewLinks.Queries,
    as: NestedLiveViewLinksQueries

  alias LiveDebugger.MockAPILiveViewDebug
  alias LiveDebugger.MockAPIStatesStorage
  alias LiveDebugger.Structs.LvState

  setup :verify_on_exit!

  describe "child_lv_process?/2" do
    test "returns true when a direct parent (state stored)" do
      parent_pid = :c.pid(0, 11, 0)
      child_pid = :c.pid(0, 12, 0)

      expect(MockAPIStatesStorage, :get!, fn ^child_pid -> %LvState{socket: %{parent_pid: parent_pid}} end)
      assert NestedLiveViewLinksQueries.child_lv_process?(parent_pid, child_pid)
    end

    test "returns true when a direct parent (state not stored)" do
      parent_pid = :c.pid(0, 11, 0)
      child_pid = :c.pid(0, 12, 0)

      expect(MockAPIStatesStorage, :get!, fn ^child_pid -> nil end)
      expect(MockAPILiveViewDebug, :socket, fn ^child_pid -> {:ok, %{parent_pid: parent_pid}} end)
      assert NestedLiveViewLinksQueries.child_lv_process?(parent_pid, child_pid)
    end

    test "returns true when not a direct parent" do
      grandparent_pid = :c.pid(0, 11, 0)
      parent_pid = :c.pid(0, 12, 0)
      child_pid = :c.pid(0, 13, 0)

      MockAPIStatesStorage
      |> expect(:get!, fn ^child_pid -> %LvState{socket: %{parent_pid: parent_pid}} end)
      |> expect(:get!, fn ^parent_pid -> %LvState{socket: %{parent_pid: grandparent_pid}} end)

      assert NestedLiveViewLinksQueries.child_lv_process?(grandparent_pid, child_pid)
    end

    test "returns false when not a parent" do
      pid = :c.pid(0, 11, 0)
      parent_pid = :c.pid(0, 12, 0)
      child_pid = :c.pid(0, 13, 0)

      MockAPIStatesStorage
      |> expect(:get!, fn ^child_pid -> %LvState{socket: %{parent_pid: parent_pid}} end)
      |> expect(:get!, fn ^parent_pid -> %LvState{socket: %{parent_pid: nil}} end)

      refute NestedLiveViewLinksQueries.child_lv_process?(pid, child_pid)
    end

    test "returns false when error" do
      parent_pid = :c.pid(0, 12, 0)
      child_pid = :c.pid(0, 13, 0)

      expect(MockAPIStatesStorage, :get!, fn ^child_pid -> nil end)
      expect(MockAPILiveViewDebug, :socket, fn ^child_pid -> {:error, :no_socket} end)
      refute NestedLiveViewLinksQueries.child_lv_process?(parent_pid, child_pid)
    end
  end
end
