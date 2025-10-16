defmodule LiveDebugger.App.Debugger.NodeState.QueriesTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries
  alias LiveDebugger.MockAPILiveViewDebug
  alias LiveDebugger.MockAPIStatesStorage
  alias LiveDebugger.Structs.LvState

  setup :verify_on_exit!

  describe "fetch_node_assigns/2" do
    test "returns assigns for a valid LiveView node when saved in storage" do
      pid = :c.pid(0, 1, 0)
      assigns = %{key: "value"}

      expect(MockAPIStatesStorage, :get!, fn ^pid -> %LvState{socket: %{assigns: assigns}} end)
      assert {:ok, %{node_assigns: ^assigns}} = NodeStateQueries.fetch_node_assigns(pid, pid)
    end

    test "returns assigns for a valid LiveView node when not saved in storage" do
      pid = :c.pid(0, 1, 0)
      assigns = %{key: "value"}

      expect(MockAPIStatesStorage, :get!, fn ^pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, %{assigns: assigns}} end)
      |> expect(:live_components, fn ^pid -> {:ok, []} end)

      assert {:ok, %{node_assigns: ^assigns}} = NodeStateQueries.fetch_node_assigns(pid, pid)
    end

    test "returns assigns for a valid component CID when saved in storage" do
      pid = :c.pid(0, 1, 0)
      cid = %Phoenix.LiveComponent.CID{cid: 2}
      assigns = %{key: "value"}

      expect(MockAPIStatesStorage, :get!, fn ^pid -> %LvState{components: [%{cid: cid.cid, assigns: assigns}]} end)
      assert {:ok, %{node_assigns: ^assigns}} = NodeStateQueries.fetch_node_assigns(pid, cid)
    end

    test "returns assigns for a valid component CID when not saved in storage" do
      pid = :c.pid(0, 1, 0)
      cid = %Phoenix.LiveComponent.CID{cid: 2}
      assigns = %{key: "value"}

      expect(MockAPIStatesStorage, :get!, fn ^pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, %{}} end)
      |> expect(:live_components, fn ^pid -> {:ok, [%{cid: cid.cid, assigns: assigns}]} end)

      assert {:ok, %{node_assigns: ^assigns}} = NodeStateQueries.fetch_node_assigns(pid, cid)
    end
  end
end
