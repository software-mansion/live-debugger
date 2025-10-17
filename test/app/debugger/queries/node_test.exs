defmodule LiveDebugger.App.Debugger.Queries.NodeTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.App.Debugger.Queries.Node, as: NodeQueries
  alias LiveDebugger.Fakes
  alias LiveDebugger.MockAPIStatesStorage
  alias LiveDebugger.Structs.LvState

  setup :verify_on_exit!

  describe "get_module_from_id/2" do
    test "returns the module from the node id when it's a live component" do
      pid = :c.pid(0, 0, 1)
      node_id = %Phoenix.LiveComponent.CID{cid: 2}

      expect(MockAPIStatesStorage, :get!, fn ^pid ->
        %LvState{pid: pid, socket: Fakes.socket(), components: Fakes.live_components()}
      end)

      assert {:ok, LiveDebuggerDev.LiveComponents.Send} =
               NodeQueries.get_module_from_id(node_id, pid)
    end

    test "returns the module from the node id when it's a live view" do
      pid = :c.pid(0, 0, 1)
      node_id = pid

      expect(MockAPIStatesStorage, :get!, fn ^pid ->
        %LvState{pid: pid, socket: Fakes.socket(view: SomeLiveView), components: Fakes.live_components()}
      end)

      assert {:ok, SomeLiveView} = NodeQueries.get_module_from_id(node_id, pid)
    end

    test "returns error when the node id is not found" do
      pid = :c.pid(0, 0, 1)
      node_id = %Phoenix.LiveComponent.CID{cid: 100}

      expect(MockAPIStatesStorage, :get!, fn ^pid ->
        %LvState{pid: pid, socket: Fakes.socket(), components: Fakes.live_components()}
      end)

      assert :error = NodeQueries.get_module_from_id(node_id, pid)
    end
  end
end
