defmodule LiveDebugger.Services.ChannelServiceTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias LiveDebugger.Services.System.ProcessService
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Structs.TreeNode

  setup do
    live_view_pid = :c.pid(0, 0, 1)
    non_live_view_pid = :c.pid(0, 1, 1)
    not_alive_pid = :c.pid(0, 1, 2)
    exited_pid = :c.pid(0, 1, 3)
    socket_id = "phx-GBsi_6M7paYhySQj"

    Mox.stub(LiveDebugger.MockProcessService, :state, fn pid ->
      case pid do
        ^live_view_pid ->
          {:ok, LiveDebugger.Fakes.state(socket_id: socket_id, root_pid: live_view_pid)}

        ^non_live_view_pid ->
          {:ok, :not_live_view}

        ^not_alive_pid ->
          {:error, :not_alive}

        ^exited_pid ->
          {:error, :timeout}
      end
    end)

    %{
      live_view_pid: live_view_pid,
      non_live_view_pid: non_live_view_pid,
      not_alive_pid: not_alive_pid,
      exited_pid: exited_pid,
      socket_id: socket_id
    }
  end

  describe "state/1" do
    test "returns the state of the LiveView channel process identified by pid", %{
      live_view_pid: pid
    } do
      {:ok, state} = ProcessService.state(pid)
      assert {:ok, ^state} = ChannelService.state(pid)
    end

    test "returns an error when the process is not a LiveView", %{non_live_view_pid: pid} do
      assert {:error, "PID:" <> _} = ChannelService.state(pid)
    end

    test "returns an error when there is no process with the given pid", %{not_alive_pid: pid} do
      assert {:error, :not_alive} = ChannelService.state(pid)
    end

    test "returns and error when something went wrong", %{exited_pid: pid} do
      assert {:error, "Could not get state from pid:" <> _} = ChannelService.state(pid)
    end
  end

  describe "get_node/2" do
    test "returns LiveView node with the given id from the channel state when pid is passed", %{
      live_view_pid: pid
    } do
      {:ok, channel_state} = ProcessService.state(pid)
      assert {:ok, node} = ChannelService.get_node(channel_state, pid)

      assert %TreeNode.LiveView{pid: ^pid} = node
    end

    test "returns LiveComponent node with the given id from the channel state when cid is passed",
         %{live_view_pid: pid} do
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      {:ok, channel_state} = ProcessService.state(pid)
      {:ok, node} = ChannelService.get_node(channel_state, cid)

      assert %TreeNode.LiveComponent{cid: ^cid} = node
    end

    test "returns `nil` when the node is not found", %{live_view_pid: pid} do
      {:ok, channel_state} = ProcessService.state(pid)

      assert {:ok, nil} =
               ChannelService.get_node(channel_state, %Phoenix.LiveComponent.CID{cid: 999})
    end
  end

  describe "build_tree/1" do
    test "creates a tree with TreeNode elements from the channel state", %{live_view_pid: pid} do
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
    test "returns node ids that are present in the channel state", %{live_view_pid: pid} do
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
