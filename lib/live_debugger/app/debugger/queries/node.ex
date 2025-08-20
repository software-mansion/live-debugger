defmodule LiveDebugger.App.Debugger.Queries.Node do
  @moduledoc """
  Queries associated with the node id.
  """

  import LiveDebugger.App.Debugger.Structs.TreeNode.Guards

  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.App.Debugger.Structs.TreeNode
  alias LiveDebugger.App.Debugger.Queries.State, as: StateQueries

  @spec get_module_from_id(TreeNode.id(), pid()) :: {:ok, module()} | :error
  def get_module_from_id(node_id, pid) when is_node_id(node_id) do
    with {:ok, state} <- StateQueries.get_lv_state(pid),
         {:ok, %TreeNode{module: module}} <- get_node(state, node_id) do
      {:ok, module}
    else
      _ -> :error
    end
  end

  defp get_node(%LvState{pid: pid} = state, pid) when is_pid(pid) do
    TreeNode.live_view_node(state)
  end

  defp get_node(state, cid) do
    with {:ok, nodes} <- TreeNode.live_component_nodes(state),
         %TreeNode{} = node <- Enum.find(nodes, fn node -> node.id == cid end) do
      {:ok, node}
    else
      _ -> :error
    end
  end
end
