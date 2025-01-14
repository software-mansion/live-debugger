defmodule LiveDebugger.Services.ChannelStateScraperTest do
  use LiveDebugger.ProcessCase, async: true

  alias LiveDebugger.Services.ChannelStateScraper
  alias LiveDebugger.Structs.TreeNode

  @cid_1 %Phoenix.LiveComponent.CID{cid: 1}

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
            }} = ChannelStateScraper.build_tree(pid)
  end

  describe "get_node_from_pid/2 " do
    test "returns live view node", %{pid: pid} do
      assert {:ok, live_view} = ChannelStateScraper.get_node_from_pid(pid, pid)
      assert %TreeNode.LiveView{pid: ^pid} = live_view
    end

    test "returns live component node", %{pid: pid} do
      assert {:ok, live_component} =
               ChannelStateScraper.get_node_from_pid(pid, @cid_1)

      assert %TreeNode.LiveComponent{id: "live_first"} = live_component
    end
  end

  describe "get_node_by_id " do
    test "returns live view node", %{pid: pid} do
      {:ok, tree} = ChannelStateScraper.build_tree(pid)
      assert %TreeNode.LiveView{pid: ^pid} = ChannelStateScraper.get_node_by_id(tree, pid)
    end

    test "returns live component node", %{pid: pid} do
      {:ok, tree} = ChannelStateScraper.build_tree(pid)

      assert %TreeNode.LiveComponent{id: "live_first"} =
               ChannelStateScraper.get_node_by_id(tree, @cid_1)
    end

    test "returns `nil` when node is not found", %{pid: pid} do
      {:ok, tree} = ChannelStateScraper.build_tree(pid)

      assert is_nil(
               ChannelStateScraper.get_node_by_id(tree, %Phoenix.LiveComponent.CID{cid: 100})
             )
    end
  end
end
