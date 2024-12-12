defmodule LiveDebugger.Services.SocketScraper do
  alias LiveDebugger.Services.TreeNode

  import LiveDebugger.Services.LiveViewScrapper

  @doc """
  Retrieves a TreeNode with the given `id` from the process identified by `pid`.
  The `id` can be either a PID or a CID.
  Returned node doesn't have children.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.State.state_from_pid(pid)
      iex> LiveDebugger.Services.SocketScraper.get_node_from_pid(pid, 2)
      %LiveDebugger.Services.TreeNode.LiveComponent{...}
  """
  @spec get_node_from_pid(pid :: pid(), id :: TreeNode.id()) ::
          {:ok, TreeNode.t() | nil} | {:error, term()}
  def get_node_from_pid(pid, id) do
    with {:ok, state} <- state_from_pid(pid) do
      case id do
        id when is_pid(id) ->
          TreeNode.live_view_node(state.socket)

        id when is_integer(id) ->
          live_component_from_state(state, id)
      end
    end
  end

  defp live_component_from_state(state, cid) do
    state
    |> get_state_components()
    |> Enum.find(fn {component_cid, _} -> component_cid == cid end)
    |> case do
      nil ->
        {:ok, nil}

      component ->
        TreeNode.live_component_node(component)
    end
  end

  @doc """
  Retrieves a TreeNode with the given `id` from the tree.
  The `id` can be either a PID or a CID.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.State.state_from_pid(pid)
      iex> tree = LiveDebugger.Services.SocketScraper.build_tree(state)
      iex> LiveDebugger.Services.SocketScraper.get_node_by_id(tree, 1)
      %LiveDebugger.Services.TreeNode.LiveComponent{...}
  """
  @spec get_node_by_id(tree :: TreeNode.t(), id :: TreeNode.id()) :: TreeNode.t() | nil
  def get_node_by_id(tree, id) do
    case tree do
      %TreeNode.LiveView{pid: ^id} -> tree
      %TreeNode.LiveComponent{cid: ^id} -> tree
      %TreeNode.LiveView{children: children} -> check_children(children, id)
      %TreeNode.LiveComponent{children: children} -> check_children(children, id)
    end
  end

  defp check_children(children, id) do
    Enum.reduce_while(children, nil, fn child, _ ->
      case get_node_by_id(child, id) do
        nil -> {:cont, nil}
        child -> {:halt, child}
      end
    end)
  end

  @doc """
  Creates a tree with the root being a LiveDebugger.Services.TreeNode.LiveView.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.State.state_from_pid(pid)
      iex> LiveDebugger.Services.SocketScraper.build_tree(state)
      {:ok, %LiveDebugger.Services.TreeNode.LiveView{...}}
  """
  @spec build_tree(pid) :: {:ok, TreeNode.t()} | {:error, term()}
  def build_tree(pid) when is_pid(pid) do
    with {:ok, state} <- state_from_pid(pid),
         {:ok, {root, live_elements}} <- get_tree_nodes(state) do
      cids_tree =
        state
        |> children_cids_mapping()
        |> tree_merge(nil)

      {:ok, add_children(root, cids_tree, live_elements)}
    end
  end

  defp get_tree_nodes(%{socket: socket} = state) do
    with {:ok, root} <- TreeNode.live_view_node(socket) do
      elements =
        state
        |> get_state_components()
        |> Enum.map(fn component ->
          case TreeNode.live_component_node(component) do
            {:ok, live_component} -> live_component
            {:error, _} -> nil
          end
        end)

      {:ok, {root, elements}}
    end
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

  defp add_children(parent_element, nil, _live_components), do: parent_element

  defp add_children(parent_element, children_cids_map, live_components) do
    Enum.reduce(children_cids_map, parent_element, fn {cid, children_cids_map}, parent_element ->
      child =
        live_components
        |> Enum.find(fn element -> element.cid == cid end)
        |> add_children(children_cids_map, live_components)

      TreeNode.add_child(parent_element, child)
    end)
  end
end
