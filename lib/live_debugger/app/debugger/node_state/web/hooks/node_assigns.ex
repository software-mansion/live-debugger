defmodule LiveDebugger.App.Debugger.NodeState.Web.Hooks.NodeAssigns do
  @moduledoc """
  This hook is responsible for fetching assigns of specific node.
  """

  use LiveDebugger.App.Web, :hook

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Debugger.NodeState.Utils, as: NodeStateUtils
  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries

  @required_assigns [
    :node_id,
    :lv_process
  ]

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:node_assigns, :handle_async, &handle_async/3)
    |> register_hook(:node_assigns)
    |> assign(:node_assigns, AsyncResult.loading())
    |> assign(:node_assigns_diff, AsyncResult.loading())
    |> assign_async_node_assigns()
  end

  def assign_async_node_assigns(socket, opts \\ [])

  def assign_async_node_assigns(
        %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket,
        opts
      )
      when not is_nil(node_id) do
    if Keyword.get(opts, :with_diff?, false) do
      socket
    else
      assign(socket, :node_assigns, AsyncResult.loading(socket.assigns.node_assigns))
    end
    |> start_async(:fetch_node_assigns, fn ->
      # Small sleep serves here as a debounce mechanism
      Process.sleep(100)
      NodeStateQueries.fetch_node_assigns(pid, node_id)
    end)
  end

  def assign_async_node_assigns(socket, _opts) do
    assign(socket, :node_assigns, AsyncResult.failed(%AsyncResult{}, :no_node_id))
    assign(socket, :node_assigns_diff, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  defp handle_async(:fetch_node_assigns, {:ok, {:ok, node_assigns}}, socket) do
    diff =
      case socket.assigns.node_assigns do
        %AsyncResult{loading: true} ->
          %{}

        %AsyncResult{result: old_node_assigns} ->
          NodeStateUtils.diff(old_node_assigns, node_assigns)
      end

    socket
    |> assign(:node_assigns, AsyncResult.ok(node_assigns))
    |> assign(:node_assigns_diff, AsyncResult.ok(diff))
    |> halt()
  end

  defp handle_async(:fetch_node_assigns, {:ok, {:error, reason}}, socket) do
    socket
    |> assign(:node_assigns, AsyncResult.failed(socket.node_assigns, reason))
    |> assign(:node_assigns_diff, AsyncResult.failed(socket.node_assigns_diff, reason))
    |> halt()
  end

  defp handle_async(:fetch_node_assigns, {:exit, reason}, socket) do
    socket
    |> assign(:node_assigns, AsyncResult.failed(socket.node_assigns, reason))
    |> assign(:node_assigns_diff, AsyncResult.failed(socket.node_assigns_diff, reason))
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}
end
