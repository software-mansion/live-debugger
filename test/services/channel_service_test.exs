defmodule LiveDebugger.Services.ChannelServiceTest do
  use LiveDebugger.SystemCase

  alias LiveDebugger.Services.System.ProcessService
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Structs.TreeNode

  describe "state/1" do
    test "returns the state of the LiveView channel process identified by pid", %{pid: pid} do
      {:ok, state} = ProcessService.state(pid)
      assert {:ok, state} == ChannelService.state(pid)
    end

    test "returns an error when the process is not a LiveView" do
      pid = self()
      assert {:error, _} = ChannelService.state(pid)
    end
  end

  describe "get_node/2" do
    test "returns LiveView node with the given id from the channel state when pid is passed", %{
      pid: pid
    } do
      {:ok, channel_state} = ProcessService.state(pid)
      assert {:ok, node} = ChannelService.get_node(channel_state, pid)

      assert %TreeNode.LiveView{pid: ^pid} = node
    end

    test "returns LiveComponent node with the given id from the channel state when cid is passed",
         %{
           pid: pid
         } do
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      {:ok, channel_state} = ProcessService.state(pid)
      {:ok, node} = ChannelService.get_node(channel_state, cid)

      assert %TreeNode.LiveComponent{cid: ^cid} = node
    end

    test "returns `nil` when the node is not found", %{pid: pid} do
      {:ok, channel_state} = ProcessService.state(pid)

      assert {:ok, nil} =
               ChannelService.get_node(channel_state, %Phoenix.LiveComponent.CID{cid: 999})
    end
  end

  describe "build_tree/1" do
    test "creates a tree with TreeNode elements from the channel state",
         %{pid: pid} do
      {:ok, channel_state} = ProcessService.state(pid)
      {:ok, tree} = ChannelService.build_tree(channel_state)

      assert %TreeNode.LiveView{
               pid: ^pid,
               children: [
                 %TreeNode.LiveComponent{
                   cid: %Phoenix.LiveComponent.CID{cid: 1},
                   children: []
                 },
                 %TreeNode.LiveComponent{
                   cid: %Phoenix.LiveComponent.CID{cid: 2},
                   children: [
                     %TreeNode.LiveComponent{
                       cid: %Phoenix.LiveComponent.CID{cid: 6},
                       children: []
                     },
                     %TreeNode.LiveComponent{
                       cid: %Phoenix.LiveComponent.CID{cid: 7},
                       children: []
                     }
                   ]
                 },
                 %TreeNode.LiveComponent{
                   cid: %Phoenix.LiveComponent.CID{cid: 3},
                   children: []
                 },
                 %TreeNode.LiveComponent{
                   cid: %Phoenix.LiveComponent.CID{cid: 4},
                   children: [
                     %TreeNode.LiveComponent{
                       cid: %Phoenix.LiveComponent.CID{cid: 5},
                       children: [
                         %TreeNode.LiveComponent{
                           cid: %Phoenix.LiveComponent.CID{cid: 8},
                           children: []
                         }
                       ]
                     }
                   ]
                 }
               ]
             } = tree
    end

    test "returns an error when the channel state is invalid" do
      channel_state = %{}
      assert {:error, _} = ChannelService.build_tree(channel_state)
    end
  end

  describe "node_ids/1" do
    test "returns node ids that are present in the channel state", %{pid: pid} do
      {:ok, channel_state} = ProcessService.state(pid)
      {:ok, node_ids} = ChannelService.node_ids(channel_state)

      assert [
               %Phoenix.LiveComponent.CID{cid: 1},
               %Phoenix.LiveComponent.CID{cid: 2},
               %Phoenix.LiveComponent.CID{cid: 3},
               %Phoenix.LiveComponent.CID{cid: 4},
               %Phoenix.LiveComponent.CID{cid: 5},
               %Phoenix.LiveComponent.CID{cid: 6},
               %Phoenix.LiveComponent.CID{cid: 7},
               %Phoenix.LiveComponent.CID{cid: 8},
               ^pid
             ] = node_ids
    end
  end
end
