defmodule LiveDebuggerRefactor.App.Debugger.ComponentsTree.UtilsTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.Fakes
  alias LiveDebuggerRefactor.Structs.LvState
  alias LiveDebuggerRefactor.App.Debugger.Structs.TreeNode
  alias LiveDebuggerRefactor.App.Debugger.ComponentsTree.Utils, as: ComponentsTreeUtils

  describe "build_tree/1" do
    test "creates a tree with TreeNode elements from the LiveView state" do
      pid = :c.pid(0, 11, 0)

      lv_state =
        %LvState{
          pid: pid,
          socket: Fakes.socket(pid: pid),
          components: Fakes.live_components()
        }

      {:ok, tree} = ComponentsTreeUtils.build_tree(lv_state)

      assert %TreeNode{
               id: ^pid,
               children: [
                 %TreeNode{
                   id: %Phoenix.LiveComponent.CID{cid: 1},
                   children: []
                 },
                 %TreeNode{
                   id: %Phoenix.LiveComponent.CID{cid: 2},
                   children: [
                     %TreeNode{
                       id: %Phoenix.LiveComponent.CID{cid: 6},
                       children: []
                     },
                     %TreeNode{
                       id: %Phoenix.LiveComponent.CID{cid: 7},
                       children: []
                     }
                   ]
                 },
                 %TreeNode{
                   id: %Phoenix.LiveComponent.CID{cid: 3},
                   children: []
                 },
                 %TreeNode{
                   id: %Phoenix.LiveComponent.CID{cid: 4},
                   children: [
                     %TreeNode{
                       id: %Phoenix.LiveComponent.CID{cid: 5},
                       children: [
                         %TreeNode{
                           id: %Phoenix.LiveComponent.CID{cid: 8},
                           children: []
                         }
                       ]
                     }
                   ]
                 }
               ]
             } = tree
    end

    test "returns an error when the LiveView state is invalid" do
      assert {:error, _} = ComponentsTreeUtils.build_tree(%LvState{})
    end
  end

  describe "max_opened_node_level/2" do
    tree = %TreeNode{
      children: [
        %TreeNode{children: []},
        %TreeNode{
          children: [
            %TreeNode{children: []},
            %TreeNode{children: []}
          ]
        },
        %TreeNode{children: []},
        %TreeNode{
          children: [
            %TreeNode{
              children: [
                %TreeNode{children: []}
              ]
            }
          ]
        }
      ]
    }

    assert 0 = ComponentsTreeUtils.max_opened_node_level(tree, 2)
    assert 1 = ComponentsTreeUtils.max_opened_node_level(tree, 5)
    assert 3 = ComponentsTreeUtils.max_opened_node_level(tree)
  end
end
