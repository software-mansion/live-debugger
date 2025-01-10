defmodule LiveDebugger.Services.ChannelStateScraper do
  @moduledoc """
  This module provides functions that performs operation on state of LiveView channel.
  """

  alias LiveDebugger.Services.TreeNode
  alias LiveDebugger.Services.LiveViewScraper

  @doc """
  Retrieves a TreeNode with the given `id` from the process identified by `pid`.
  The `id` can be either a PID or a CID.
  Returned node doesn't have children.

  ## Examples
      iex> LiveDebugger.Services.ChannelStateScraper.get_node_from_pid(pid, %Phoenix.LiveComponent.CID{cid: 1})
      %LiveDebugger.Services.TreeNode.LiveComponent{...}

      iex> LiveDebugger.Services.ChannelStateScraper.get_node_from_pid(pid, pid)
      %LiveDebugger.Services.TreeNode.LiveView{...}
  """
  @spec get_node_from_pid(pid :: pid(), id :: TreeNode.id()) ::
          {:ok, TreeNode.t() | nil} | {:error, term()}
  def get_node_from_pid(pid, id) do
    with {:ok, channel_state} <- LiveViewScraper.channel_state_from_pid(pid) do
      case id do
        pid when is_pid(pid) ->
          TreeNode.live_view_node(channel_state)

        %Phoenix.LiveComponent.CID{} = cid ->
          TreeNode.live_component_node(channel_state, cid)
      end
    end
  end

  @doc """
  Retrieves a TreeNode with the given `id` from the tree.
  The `id` can be either a PID or a CID.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.LiveViewScraper.channel_state_from_pid(pid)
      iex> tree = LiveDebugger.Services.ChannelStateScraper.build_tree(state)
      iex> LiveDebugger.Services.ChannelStateScraper.get_node_by_id(tree, %Phoenix.LiveComponent.CID{cid: 1})
      %LiveDebugger.Services.TreeNode.LiveComponent{...}
  """
  @spec get_node_by_id(tree :: TreeNode.t(), id :: TreeNode.id()) :: TreeNode.t() | nil
  def get_node_by_id(tree, id) do
    case tree do
      %TreeNode.LiveView{pid: ^id} -> tree
      %TreeNode.LiveComponent{cid: ^id} -> tree
      node -> check_children(node.children, id)
    end
  end

  @doc """
  Creates a tree with the root being a LiveDebugger.Services.TreeNode.LiveView.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.LiveViewScraper.channel_state_from_pid(pid)
      iex> LiveDebugger.Services.ChannelStateScraper.build_tree(state)
      {:ok, %LiveDebugger.Services.TreeNode.LiveView{...}}
  """
  @spec build_tree(pid) :: {:ok, TreeNode.t()} | {:error, term()}
  def build_tree(pid) when is_pid(pid) do
    with {:ok, channel_state} <- LiveViewScraper.channel_state_from_pid(pid),
         {:ok, live_view} <- TreeNode.live_view_node(channel_state),
         {:ok, live_components} <- TreeNode.live_component_nodes(channel_state) do
      cids_tree =
        channel_state
        |> children_cids_mapping()
        |> tree_merge(nil)

      {:ok, add_children(live_view, cids_tree, live_components)}
    end
  end

  # We'll have to refactor this module so the functions will accept the channel state, not pid
  # Thanks to this approach we'll have more control on channel state scraping
  # In this module we'll just parse the state

  @doc """
  Returns node ids that are present in the channel state where node can be both LiveView or LiveComponent.
  For LiveView, the id is the PID of the process. For LiveComponent, the id is the CID.
  """

  @spec all_node_ids(pid :: pid()) :: {:ok, [TreeNode.id()]} | {:error, term()}
  def all_node_ids(pid) do
    with {:ok, channel_state} <- LiveViewScraper.channel_state_from_pid(pid),
         component_cids <- channel_state |> get_state_components() |> Map.keys() do
      {:ok, Enum.map(component_cids, fn cid -> %Phoenix.LiveComponent.CID{cid: cid} end) ++ [pid]}
    end
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

  defp check_children(children, id) do
    Enum.reduce_while(children, nil, fn child, _ ->
      case get_node_by_id(child, id) do
        nil -> {:cont, nil}
        child -> {:halt, child}
      end
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
