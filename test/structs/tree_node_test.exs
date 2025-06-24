defmodule LiveDebugger.Structs.TreeNodeTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Structs.TreeNode

  @cid_1 %Phoenix.LiveComponent.CID{cid: 1}

  describe "id/1" do
    test "returns pid for LiveView" do
      pid = :c.pid(0, 0, 0)
      node = %TreeNode.LiveView{pid: pid}

      assert TreeNode.id(node) == pid
    end

    test "returns cid for LiveComponent" do
      node = %TreeNode.LiveComponent{cid: @cid_1}

      assert TreeNode.id(node) == @cid_1
    end
  end

  describe "type/1" do
    test "returns :live_view for LiveView" do
      node = %TreeNode.LiveView{}

      assert TreeNode.type(node) == :live_view
    end

    test "returns :live_component for LiveComponent" do
      node = %TreeNode.LiveComponent{}

      assert TreeNode.type(node) == :live_component
    end

    test "returns :live_view for pid" do
      pid = :c.pid(0, 0, 0)

      assert TreeNode.type(pid) == :live_view
    end

    test "returns :live_component for cid" do
      assert TreeNode.type(@cid_1) == :live_component
    end
  end

  describe "display_id/1" do
    test "returns string representation of pid" do
      pid = :c.pid(0, 0, 0)
      node = %TreeNode.LiveView{pid: pid}

      assert TreeNode.display_id(node) == "0.0.0"
    end

    test "returns string representation of cid" do
      node = %TreeNode.LiveComponent{cid: @cid_1}

      assert TreeNode.display_id(node) == "1"
    end
  end

  describe "id_from_string/1" do
    test "parses pid from string" do
      pid = :c.pid(0, 0, 0)
      id = "0.0.0"

      assert TreeNode.id_from_string(id) == {:ok, pid}
    end

    test "parses cid from string" do
      id = "1"

      assert TreeNode.id_from_string(id) == {:ok, @cid_1}
    end

    test "returns :error for invalid string" do
      assert TreeNode.id_from_string("invalid") == :error
    end
  end

  test "add_child/2 adds child to the parent" do
    parent = %TreeNode.LiveView{children: []}
    child = %TreeNode.LiveComponent{cid: @cid_1}

    assert TreeNode.add_child(parent, child) == %TreeNode.LiveView{children: [child]}
  end

  describe "get_child/2" do
    test "returns nil for non-existing TreeNode.LiveView child" do
      parent = %TreeNode.LiveView{
        children: [
          %TreeNode.LiveComponent{cid: @cid_1}
        ]
      }

      child_id = :c.pid(0, 0, 0)

      assert TreeNode.get_child(parent, child_id) == nil
    end

    test "returns nil for non-existing TreeNode.LiveComponent child" do
      parent = %TreeNode.LiveView{
        children: [
          %TreeNode.LiveView{pid: :c.pid(0, 0, 0)}
        ]
      }

      child_id = @cid_1

      assert TreeNode.get_child(parent, child_id) == nil
    end

    test "returns child for existing pid" do
      pid = :c.pid(0, 0, 0)
      parent = %TreeNode.LiveView{children: [%TreeNode.LiveView{pid: pid}]}

      assert TreeNode.get_child(parent, pid) == %TreeNode.LiveView{pid: pid}
    end

    test "returns child for existing cid" do
      cid = @cid_1
      parent = %TreeNode.LiveView{children: [%TreeNode.LiveComponent{cid: cid}]}

      assert TreeNode.get_child(parent, cid) == %TreeNode.LiveComponent{cid: cid}
    end
  end

  describe "live_view_node/1" do
    test "returns TreeNode.LiveView for a valid channel_state" do
      pid = :c.pid(0, 0, 0)

      state = %{
        socket: %{
          id: 1,
          root_pid: pid,
          view: :view,
          assigns: %{}
        }
      }

      assert {:ok,
              %TreeNode.LiveView{id: 1, pid: ^pid, module: :view, assigns: %{}, children: []}} =
               TreeNode.live_view_node(state)
    end

    test "returns error for invalid channel_state" do
      assert TreeNode.live_view_node(%{}) == {:error, :invalid_channel_view}
    end
  end

  describe "live_component_node/2" do
    test "returns TreeNode.LiveComponent for a valid channel_state" do
      channel_state = %{
        components: [
          %{cid: 1, module: :module, id: "component-id", assigns: %{}, children_cids: []}
        ]
      }

      cid = @cid_1

      assert {:ok, %TreeNode.LiveComponent{cid: ^cid, module: :module}} =
               TreeNode.live_component_node(channel_state, cid)
    end

    test "returns nil for non-existing live_component" do
      channel_state = %{
        components: [
          %{cid: 1, module: :module, id: "component-id", assigns: %{}, children_cids: []}
        ]
      }

      assert {:ok, nil} =
               TreeNode.live_component_node(channel_state, %Phoenix.LiveComponent.CID{cid: 2})
    end

    test "returns error for invalid channel_state" do
      component = %{}

      assert {:error, :invalid_channel_state} =
               TreeNode.live_component_node(component, @cid_1)
    end
  end

  describe "live_component_nodes/1" do
    test "returns list of live components" do
      %{cid: 1, module: :module, id: "component-id-1", assigns: %{}, children_cids: []}

      channel_state = %{
        components: [
          %{cid: 1, module: :module, id: "component-id-1", assigns: %{}, children_cids: []},
          %{cid: 2, module: :module, id: "component-id-1", assigns: %{}, children_cids: []}
        ]
      }

      assert {:ok, [%TreeNode.LiveComponent{}, %TreeNode.LiveComponent{}]} =
               TreeNode.live_component_nodes(channel_state)
    end

    test "returns empty list for empty channel_state" do
      channel_state = %{
        components: []
      }

      assert {:ok, []} = TreeNode.live_component_nodes(channel_state)
    end

    test "returns error for invalid channel_state" do
      channel_state = %{}

      assert {:error, :invalid_channel_state} = TreeNode.live_component_nodes(channel_state)
    end
  end
end
