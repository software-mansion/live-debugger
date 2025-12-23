defmodule LiveDebugger.App.Debugger.NodeState.QueriesTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Fakes
  alias LiveDebugger.MockAPITracesStorage
  alias LiveDebugger.MockAPIStatesStorage
  alias LiveDebugger.MockAPILiveViewDebug
  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries

  setup :verify_on_exit!

  describe "fetch_node_assigns/2" do
    test "returns assigns for a valid LiveView node when saved in storage" do
      pid = :c.pid(0, 1, 0)
      assigns = %{key: "value"}

      MockAPIStatesStorage
      |> expect(:get!, fn ^pid -> %LvState{socket: %{assigns: assigns}} end)

      assert {:ok, ^assigns} = NodeStateQueries.fetch_node_assigns(pid, pid)
    end

    test "returns assigns for a valid LiveView node when not saved in storage" do
      pid = :c.pid(0, 1, 0)
      assigns = %{key: "value"}

      MockAPIStatesStorage
      |> expect(:get!, fn ^pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, %{assigns: assigns}} end)
      |> expect(:live_components, fn ^pid -> {:ok, []} end)

      assert {:ok, ^assigns} = NodeStateQueries.fetch_node_assigns(pid, pid)
    end

    test "returns assigns for a valid component CID when saved in storage" do
      pid = :c.pid(0, 1, 0)
      cid = %Phoenix.LiveComponent.CID{cid: 2}
      assigns = %{key: "value"}

      MockAPIStatesStorage
      |> expect(:get!, fn ^pid -> %LvState{components: [%{cid: cid.cid, assigns: assigns}]} end)

      assert {:ok, ^assigns} = NodeStateQueries.fetch_node_assigns(pid, cid)
    end

    test "returns assigns for a valid component CID when not saved in storage" do
      pid = :c.pid(0, 1, 0)
      cid = %Phoenix.LiveComponent.CID{cid: 2}
      assigns = %{key: "value"}

      MockAPIStatesStorage
      |> expect(:get!, fn ^pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, %{}} end)
      |> expect(:live_components, fn ^pid -> {:ok, [%{cid: cid.cid, assigns: assigns}]} end)

      assert {:ok, ^assigns} = NodeStateQueries.fetch_node_assigns(pid, cid)
    end
  end

  describe "fetch_node_temporary_assigns/2" do
    test "returns temporary assigns for given node" do
      pid = :c.pid(0, 11, 0)
      node_id = pid

      assigns = %{
        temp_assign: "some value",
        other_assign: 124,
        socket: %{
          private: %{
            temporary_assigns: %{
              temp_assign: nil
            }
          }
        }
      }

      MockAPITracesStorage
      |> expect(:get!, fn ^pid, [node_id: ^node_id, functions: ["render/1"], limit: 1] ->
        {[Fakes.trace(args: [assigns])], nil}
      end)

      assert {:ok, %{temp_assign: "some value"}} =
               NodeStateQueries.fetch_node_temporary_assigns(pid, node_id)
    end
  end

  test "returns empty map when no temporary assigns for given node" do
    pid = :c.pid(0, 11, 0)
    node_id = pid

    assigns = %{
      some_assign: "some value",
      other_assign: 124,
      socket: %{private: %{}}
    }

    MockAPITracesStorage
    |> expect(:get!, fn ^pid, [node_id: ^node_id, functions: ["render/1"], limit: 1] ->
      {[Fakes.trace(args: [assigns])], nil}
    end)

    assert {:ok, %{}} =
             NodeStateQueries.fetch_node_temporary_assigns(pid, node_id)
  end

  test "return errror when no render traces recorded" do
    pid = :c.pid(0, 11, 0)
    node_id = pid

    MockAPITracesStorage
    |> expect(:get!, fn ^pid, [node_id: ^node_id, functions: ["render/1"], limit: 1] ->
      :end_of_table
    end)

    assert {:error, :no_render_trace} =
             NodeStateQueries.fetch_node_temporary_assigns(pid, node_id)
  end

  test "return errror when traces storage fails" do
    pid = :c.pid(0, 11, 0)
    node_id = pid

    MockAPITracesStorage
    |> expect(:get!, fn ^pid, [node_id: ^node_id, functions: ["render/1"], limit: 1] ->
      raise ArgumentError, "Wrong table identifier"
    end)

    assert {:error, %ArgumentError{message: "Wrong table identifier"}} =
             NodeStateQueries.fetch_node_temporary_assigns(pid, node_id)
  end
end
