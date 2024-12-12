defmodule LiveDebugger.Service.TreeNodeTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Service.TreeNode

  test "add_child/2" do
    parent = %TreeNode.LiveView{children: []}
    child = %TreeNode.LiveComponent{cid: 1}

    assert TreeNode.add_child(parent, child) == %TreeNode.LiveView{children: [child]}
  end

  test "get_child/2 with cid" do
    parent = %TreeNode.LiveView{children: [%TreeNode.LiveComponent{cid: 1}]}

    assert [TreeNode.get_child(parent, 1)] == parent.children
  end

  test "get_child/2 with pid" do
    pid = :c.pid(0, 0, 0)
    parent = %TreeNode.LiveView{children: [%TreeNode.LiveView{pid: pid}]}

    assert parent.children == [TreeNode.get_child(parent, pid)]
  end

  test "live_view_node/1" do
    pid = :c.pid(0, 0, 0)
    state = %{
      id: 1,
      root_pid: pid,
      view: :view,
      assigns: %{}
    }

    assert {:ok, %TreeNode.LiveView{id: 1, pid: ^pid, module: :view, assigns: %{}, children: []}} = TreeNode.live_view_node(state)
  end

  test "live_view_node/1 with invalid view" do
    assert TreeNode.live_view_node(%{}) == {:error, :invalid_view}
  end

  test "live_component_node/1" do
    component = %{}

    assert {:error, :invalid_component} = TreeNode.live_component_node(component)
  end

  test "live_component_node/1 with valid component" do
    component = {1, {:module, "component-id", %{}, nil, nil}}

    assert {:ok, %TreeNode.LiveComponent{cid: 1, module: :module}} = TreeNode.live_component_node(component)
  end
end
