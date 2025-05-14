defmodule LiveDebugger.Services.ChannelService do
  @moduledoc """
  This module provides functions that performs operation on state of LiveView channel.
  """

  alias LiveDebugger.Services.System.ProcessService
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.CommonTypes
  alias LiveDebugger.GenServers.StateServer

  @doc """
  Retrieves the state of the LiveView channel process identified by `pid`.
  """
  @spec state(pid :: pid(), mode :: :cache | :fetch) ::
          {:ok, CommonTypes.channel_state()} | {:error, term()}
  @spec state(pid :: pid()) :: {:ok, CommonTypes.channel_state()} | {:error, term()}
  def state(pid, mode \\ :cache)

  def state(pid, :cache) when is_pid(pid) do
    StateServer.get(pid)
  end

  def state(pid, :fetch) when is_pid(pid) do
    ProcessService.state(pid)
  end

  @doc """
  Retrieves a TreeNode with the given `id` from the channel state
  The `id` can be either a PID or a CID.
  Returned node doesn't have children.
  """
  @spec get_node(channel_state :: CommonTypes.channel_state(), id :: TreeNode.id()) ::
          {:ok, TreeNode.t() | nil} | {:error, term()}
  def get_node(channel_state, id) do
    case id do
      pid when is_pid(pid) ->
        TreeNode.live_view_node(channel_state)

      %Phoenix.LiveComponent.CID{} = cid ->
        TreeNode.live_component_node(channel_state, cid)
    end
  end

  @doc """
  Creates a tree with LiveDebugger.Structs.TreeNode elements from the channel state.
  """
  @spec build_tree(channel_state :: CommonTypes.channel_state()) ::
          {:ok, TreeNode.t()} | {:error, term()}
  def build_tree(channel_state) do
    with {:ok, live_view} <- TreeNode.live_view_node(channel_state),
         {:ok, live_components} <- TreeNode.live_component_nodes(channel_state) do
      cid_tree =
        channel_state
        |> children_cids_mapping()
        |> tree_merge(nil)

      {:ok, add_children(live_view, cid_tree, live_components)}
    end
  end

  @doc """
  Returns node ids that are present in the channel state where node can be both LiveView or LiveComponent.
  For LiveView, the id is the PID of the process. For LiveComponent, the id is the CID.
  """
  @spec node_ids(channel_state :: CommonTypes.channel_state()) ::
          {:ok, [TreeNode.id()]} | {:error, term()}
  def node_ids(channel_state) do
    component_cids = channel_state |> get_state_components() |> Map.keys()
    pid = channel_state.socket.root_pid

    {:ok, Enum.map(component_cids, fn cid -> %Phoenix.LiveComponent.CID{cid: cid} end) ++ [pid]}
  end

  defp add_children(parent_element, nil, _live_components), do: parent_element

  defp add_children(parent_element, children_cids_map, live_components) do
    Enum.reduce(children_cids_map, parent_element, fn {cid, children_cids_map}, parent_element ->
      child =
        live_components
        |> Enum.find(fn element -> element.cid.cid == cid end)
        |> add_children(children_cids_map, live_components)

      TreeNode.add_child(parent_element, child)
    end)
  end

  defp children_cids_mapping(channel_state) do
    components = get_state_components(channel_state)

    components
    |> get_base_parent_cids_mapping()
    |> fill_parent_cids_mapping(components)
    |> reverse_mapping()
  end

  defp get_state_components(%{components: {components, _, _}}), do: components

  defp get_base_parent_cids_mapping(components) do
    components
    |> Enum.map(fn {cid, _} -> {cid, nil} end)
    |> Enum.into(%{})
  end

  defp fill_parent_cids_mapping(base_parent_cids_mapping, components) do
    Enum.reduce(components, base_parent_cids_mapping, fn {cid, element}, parent_cids_mapping ->
      {_, _, _, info, _} = element
      children_cids = info.children_cids

      Enum.reduce(children_cids, parent_cids_mapping, fn child_cid, parent_cids ->
        %{parent_cids | child_cid => cid}
      end)
    end)
  end

  defp reverse_mapping(components_with_children) do
    Enum.reduce(components_with_children, %{}, fn {cid, parent_cid}, components_cids_map ->
      Map.update(components_cids_map, parent_cid, [cid], &[cid | &1])
    end)
  end

  defp tree_merge(components_cids_mapping, parent_cid) do
    case Map.pop(components_cids_mapping, parent_cid) do
      {nil, _} ->
        nil

      {children_cids, components_cids_map} ->
        Enum.map(children_cids, fn cid ->
          {cid, tree_merge(components_cids_map, cid)}
        end)
        |> Enum.into(%{})
    end
  end
end
