defmodule LiveDebugger.Service.SocketScraperTest do
  use LiveDebugger.ProcessCase

  alias LiveDebugger.Service.SocketScraper
  alias LiveDebugger.Service.TreeNode

  @pid :c.pid(0, 0, 0)

  test "build_tree/1 creates tree of components" do
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
            }} = SocketScraper.build_tree(@pid)
  end

  test "get_node_from_pid/2 returns live view node" do
    assert {:ok, live_view} = SocketScraper.get_node_from_pid(@pid, @pid)
    assert %TreeNode.LiveView{id: "phx-live-view-id"} = live_view
  end

  test "get_node_from_pid/2 returns live component node" do
    assert {:ok, live_component} = SocketScraper.get_node_from_pid(@pid, 1)
    assert %TreeNode.LiveComponent{id: "live_first"} = live_component
  end
end
