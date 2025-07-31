defmodule LiveDebuggerRefactor.App.Debugger.Web.Helpers.NestedLiveView do
  @moduledoc """
  This module contains helper functions for nested live views.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias LiveDebuggerRefactor.App.Debugger.TreeNode
  alias LiveDebuggerRefactor.App.Web.Helpers.Routes, as: RoutesHelper

  @doc """
  Assigns node_id to the socket.

  If node_id is provided via session or params, it will be parsed and assigned to the socket.
  If node_id is not provided, the PID of the LiveView process will be assigned to the socket.
  If node_id is invalid, the user will be redirected to the error page.
  """
  @spec assign_node_id(Phoenix.LiveView.Socket.t(), map()) :: Phoenix.LiveView.Socket.t()
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

      :error ->
        push_navigate(socket, to: RoutesHelper.error("invalid_node_id"))
    end
  end
end
