defmodule LiveDebuggerWeb.Helpers.NestedLiveViewHelper do
  @moduledoc """
  This module contains helper functions for nested live views.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias LiveDebugger.Structs.TreeNode
  alias LiveDebuggerWeb.Helpers.RoutesHelper

  def assign_node_id(socket, %{"params" => %{"node_id" => node_id}} = _session) do
    do_assign_node_id(socket, node_id)
  end

  def assign_node_id(socket, %{"node_id" => node_id} = _params) do
    do_assign_node_id(socket, node_id)
  end

  def assign_node_id(socket, _) do
    assign(socket, :node_id, socket.assigns.lv_process.pid)
  end

  defp do_assign_node_id(socket, node_id) do
    node_id
    |> TreeNode.id_from_string()
    |> case do
      {:ok, node_id} ->
        assign(socket, :node_id, node_id)

      {:error, _} ->
        push_navigate(socket, to: RoutesHelper.error("invalid_node_id"))
    end
  end
end
