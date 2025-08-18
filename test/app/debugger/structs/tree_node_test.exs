defmodule LiveDebugger.App.Debugger.Structs.TreeNodeTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.Fakes
  alias LiveDebugger.App.Debugger.Structs.TreeNode

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

  describe "id_from_string/1" do
    test "parses PID from string" do
      assert {:ok, :c.pid(0, 1, 0)} == TreeNode.id_from_string("0.1.0")
    end

    test "parses CID from string" do
      assert {:ok, %Phoenix.LiveComponent.CID{cid: 2}} == TreeNode.id_from_string("2")
    end

    test "returns :error for invalid string" do
      assert :error == TreeNode.id_from_string("invalid")
    end
  end

  test "add_child/2 adds a child to the parent node" do
    parent = Fakes.tree_node_live_view(children: [])
    child = Fakes.tree_node_live_component()

    updated_parent = TreeNode.add_child(parent, child)

    assert [^child] = updated_parent.children
  end

  describe "live_view_node/1" do
    test "creates a LiveView node with proper values" do
      lv_state =
        %LvState{
          pid: :c.pid(0, 11, 0),
          socket: Fakes.socket(),
          components: []
        }

      assert {:ok, node} = TreeNode.live_view_node(lv_state)

      assert %TreeNode{
               id: lv_state.pid,
               dom_id: %{
                 attribute: "id",
                 value: lv_state.socket.id
               },
               type: :live_view,
               module: lv_state.socket.view,
               children: []
             } == node
    end

    test "returns :error when invalid LiveView state" do
      lv_state =
        %LvState{
          pid: :c.pid(0, 11, 0),
          socket: %{},
          components: []
        }

      assert {:error, :invalid_lv_state} == TreeNode.live_view_node(lv_state)
    end
  end

  describe "live_component_nodes/1" do
    test "returns LiveComponent nodes from LvState" do
      lv_state =
        %LvState{
          socket: %{id: "phx-somevalueid"},
          components: [
            %{
              cid: 1,
              module: LiveDebuggerTest.LiveComponent
            },
            %{
              cid: 2,
              module: LiveDebuggerTest.LiveComponent
            }
          ]
        }

      assert {:ok, nodes} = TreeNode.live_component_nodes(lv_state)

      assert [
               %TreeNode{
                 id: %Phoenix.LiveComponent.CID{cid: 2},
                 dom_id: %{attribute: "data-phx-id", value: "c2-phx-somevalueid"},
                 type: :live_component,
                 module: LiveDebuggerTest.LiveComponent,
                 children: []
               },
               %TreeNode{
                 id: %Phoenix.LiveComponent.CID{cid: 1},
                 dom_id: %{attribute: "data-phx-id", value: "c1-phx-somevalueid"},
                 type: :live_component,
                 module: LiveDebuggerTest.LiveComponent,
                 children: []
               }
             ] = nodes
    end

    test "returns :error when invalid LiveView state" do
      lv_state =
        %LvState{
          socket: %{},
          components: []
        }

      assert {:error, :invalid_lv_state} == TreeNode.live_component_nodes(lv_state)
    end

    test "returns :error when invalid LiveComponent" do
      lv_state =
        %LvState{
          socket: %{id: "phx-somevalueid"},
          components: [
            %{
              module: LiveDebuggerTest.LiveComponent
            }
          ]
        }

      assert {:error, :invalid_live_component} == TreeNode.live_component_nodes(lv_state)
    end
  end
end
