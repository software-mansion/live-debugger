defmodule LiveDebugger.Service.SocketScraper do
  alias LiveDebugger.Service.TreeNode

  @doc """
  Creates tree using LiveDebugger.Service.TreeNode where root is a  LiveDebugger.Service.TreeNode.LiveView.

  ## Examples

      iex> state = :sys.get_state(pid)
      iex> LiveDebugger.Service.SocketScraper.build_tree(state)
      {:ok, %LiveDebugger.Service.TreeNode.LiveView{...}}
  """
  @spec build_tree(pid) :: {:ok, TreeNode.t()} | {:error, term()}
  def build_tree(pid) when is_pid(pid) do
    state = :sys.get_state(pid)

    with {:ok, {root, live_elements}} <- get_tree_nodes(state) do
      cids_tree =
        state
        |> children_cids_mapping()
        |> tree_merge(nil)

      {:ok, add_children(root, cids_tree, live_elements)}
    end
  end

  defp get_tree_nodes(%{socket: socket, components: components}) do
    with {:ok, root} <- TreeNode.live_view_node(socket),
         {components, _, _} <- components do
      elements =
        Enum.map(components, fn component ->
          case TreeNode.live_component_node(component) do
            {:ok, live_component} -> live_component
            {:error, _} -> nil
          end
        end)

      {:ok, {root, elements}}
    end
  end

  defp children_cids_mapping(channel_state) do
    {components, _, _} = channel_state.components

    components
    |> get_base_parent_cids_mapping()
    |> fill_parent_cids_mapping(components)
    |> reverse_mapping()
  end

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
