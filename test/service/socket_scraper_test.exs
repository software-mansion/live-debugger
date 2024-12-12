defmodule LiveDebugger.Service.SocketScraperTest do
  use LiveDebugger.ProcessCase, async: true

  alias LiveDebugger.Service.SocketScraper
  alias LiveDebugger.Service.TreeNode

  test "build_tree/1 creates tree of components", %{pid: pid} do
    assert {:ok,
            %TreeNode.LiveView{
              id: "phx-live-view-id",
              children: [
                %TreeNode.LiveComponent{
                  id: "live_first",
                  children: [
                    %TreeNode.LiveComponent{
                      id: "live_third",
                      children: []
                    },
                    %TreeNode.LiveComponent{
                      id: "live_fourth",
                      children: [
                        %TreeNode.LiveComponent{
                          id: "live_fifth",
                          children: []
                        }
                      ]
                    }
                  ]
                },
                %TreeNode.LiveComponent{
                  id: "live_second",
                  children: []
                }
              ]
            }} = SocketScraper.build_tree(pid)
  end

  describe "get_node_from_pid/2 " do
    test "returns live view node", %{pid: pid} do
      assert {:ok, live_view} = SocketScraper.get_node_from_pid(pid, pid)
      assert %TreeNode.LiveView{pid: ^pid} = live_view
    end

    test "returns live component node", %{pid: pid} do
      assert {:ok, live_component} = SocketScraper.get_node_from_pid(pid, 1)
      assert %TreeNode.LiveComponent{id: "live_first"} = live_component
    end
  end

  describe "get_node_by_id " do
    test "returns live view node", %{pid: pid} do
      {:ok, tree} = SocketScraper.build_tree(pid)
      assert %TreeNode.LiveView{pid: ^pid} = SocketScraper.get_node_by_id(tree, pid)
    end

    test "returns live component node", %{pid: pid} do
      {:ok, tree} = SocketScraper.build_tree(pid)
      assert %TreeNode.LiveComponent{id: "live_first"} = SocketScraper.get_node_by_id(tree, 1)
    end

    test "returns `nil` when node is not found", %{pid: pid} do
      {:ok, tree} = SocketScraper.build_tree(pid)
      assert is_nil(SocketScraper.get_node_by_id(tree, 100))
    end
  end
end
