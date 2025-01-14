defmodule LiveDebugger.Structs.TreeNodeTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Structs.TreeNode

  @cid_1 %Phoenix.LiveComponent.CID{cid: 1}

  test "add_child/2" do
    parent = %TreeNode.LiveView{children: []}
    child = %TreeNode.LiveComponent{cid: @cid_1}

    assert TreeNode.add_child(parent, child) == %TreeNode.LiveView{children: [child]}
  end

  test "get_child/2 with cid" do
    cid = @cid_1

    parent = %TreeNode.LiveView{
      children: [%TreeNode.LiveComponent{cid: cid}]
    }

    assert [TreeNode.get_child(parent, cid)] == parent.children
  end

  test "get_child/2 with pid" do
    pid = :c.pid(0, 0, 0)
    parent = %TreeNode.LiveView{children: [%TreeNode.LiveView{pid: pid}]}

    assert parent.children == [TreeNode.get_child(parent, pid)]
  end

  test "live_view_node/1 with valid channel_state" do
    pid = :c.pid(0, 0, 0)

    state = %{
      socket: %{
        id: 1,
        root_pid: pid,
        view: :view,
        assigns: %{}
      }
    }

    assert {:ok, %TreeNode.LiveView{id: 1, pid: ^pid, module: :view, assigns: %{}, children: []}} =
             TreeNode.live_view_node(state)
  end

  test "live_view_node/1 with invalid view" do
    assert TreeNode.live_view_node(%{}) == {:error, :invalid_channel_view}
  end

  test "live_component_node/2 with valid channel_state and existing live_component" do
    channel_state = %{components: {%{1 => {:module, "component-id", %{}, nil, nil}}, nil, nil}}

    cid = @cid_1

    assert {:ok, %TreeNode.LiveComponent{cid: ^cid, module: :module}} =
             TreeNode.live_component_node(channel_state, cid)
  end

  test "live_component_node/2 with valid channel_state and non-existing live_component" do
    channel_state = %{components: {%{1 => {:module, "component-id", %{}, nil, nil}}, nil, nil}}

    assert {:ok, nil} =
             TreeNode.live_component_node(channel_state, %Phoenix.LiveComponent.CID{cid: 2})
  end

  test "live_component_node/2 with invalid channel_state" do
    component = %{}

    assert {:error, :invalid_channel_state} =
             TreeNode.live_component_node(component, @cid_1)
  end

  test "live_component_nodes/1 with valid channel_state" do
    channel_state = %{
      components:
        {%{
           1 => {:module, "component-id-2", %{}, nil, nil},
           2 => {:module, "component-id-2", %{}, nil, nil}
         }, nil, nil}
    }

    assert {:ok, live_components} =
             TreeNode.live_component_nodes(channel_state)

    assert length(live_components) == 2
  end
end
