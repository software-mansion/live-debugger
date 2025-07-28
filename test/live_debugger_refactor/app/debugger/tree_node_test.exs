defmodule LiveDebuggerRefactor.App.Debugger.TreeNodeTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.Fakes
  alias LiveDebuggerRefactor.App.Debugger.TreeNode

  describe "parse_id/1" do
    test "parses id for LiveView" do
      pid = :c.pid(0, 1, 0)

      tree_node = Fakes.tree_node_live_view(id: pid)

      assert "0.1.0" == TreeNode.parse_id(tree_node)
    end

    test "parses id for LiveComponent" do
      cid = %Phoenix.LiveComponent.CID{cid: 2}

      tree_node = Fakes.tree_node_live_component(id: cid)

      assert "2" == TreeNode.parse_id(tree_node)
    end
  end
end
