defmodule LiveDebugger.App.Debugger.ComponentsTree.Utils do
  @moduledoc """
  Utility functions for the Components Tree.
  """

  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.App.Debugger.Structs.TreeNode

  @max_node_number 20

  @doc """
  Calculates the maximum level to be opened in the tree.
  """
  @spec max_opened_node_level(root_node :: TreeNode.t(), max_nodes :: integer()) :: integer()
  def max_opened_node_level(root_node, max_nodes \\ @max_node_number) do
    node_count = count_by_level(root_node)

    node_count
    |> Enum.reduce_while({0, 0}, fn {level, count}, acc ->
      {_, parent_count} = acc
      new_count = count + parent_count

      if new_count > max_nodes do
        {:halt, {level - 1, new_count}}
      else
        {:cont, {level, new_count}}
      end
    end)
    |> elem(0)
  end

  defp count_by_level(node, level \\ 0, acc \\ %{}) do
    acc = Map.update(acc, level, 1, &(&1 + 1))

    Enum.reduce(node.children, acc, fn child, acc ->
      count_by_level(child, level + 1, acc)
    end)
  end

  @doc """
  Creates a tree with `LiveDebugger.App.Debugger.Structs.TreeNode` elements from the live view state.
  """
  @spec build_tree(lv_state :: LvState.t()) :: {:ok, TreeNode.t()} | {:error, term()}
  def build_tree(lv_state) do
    with {:ok, live_view} <- TreeNode.live_view_node(lv_state),
         {:ok, live_components} <- TreeNode.live_component_nodes(lv_state) do
      cid_tree =
        lv_state
        |> children_cids_mapping()
        |> tree_merge(nil)

      {:ok, add_children(live_view, cid_tree, live_components)}
    end
  end

  defp children_cids_mapping(%{components: components}) do
    components
    |> get_base_parent_cids_mapping()
    |> fill_parent_cids_mapping(components)
    |> reverse_mapping()
  end

  defp get_base_parent_cids_mapping(components) do
    components
    |> Enum.map(fn %{cid: cid} -> {cid, nil} end)
    |> Enum.into(%{})
  end

  defp fill_parent_cids_mapping(base_parent_cids_mapping, components) do
    Enum.reduce(components, base_parent_cids_mapping, fn element, parent_cids_mapping ->
      Enum.reduce(element.children_cids, parent_cids_mapping, fn child_cid, parent_cids ->
        %{parent_cids | child_cid => element.cid}
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
        children_cids
        |> Enum.map(fn cid -> {cid, tree_merge(components_cids_map, cid)} end)
        |> Enum.into(%{})
    end
  end

  defp add_children(parent_element, nil, _live_components), do: parent_element

  defp add_children(parent_element, children_cids_map, live_components) do
    Enum.reduce(children_cids_map, parent_element, fn {cid, children_cids_map}, parent_element ->
      child =
        live_components
        |> Enum.find(fn element -> element.id.cid == cid end)
        |> add_children(children_cids_map, live_components)

      TreeNode.add_child(parent_element, child)
    end)
  end
end
