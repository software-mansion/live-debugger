defmodule LiveDebugger.App.Debugger.NodeState.Web.Hooks.TemporaryAssigns do
  @moduledoc """
  This hook is responsible for fetching temporary assigns of specific node.
  """

  use LiveDebugger.App.Web, :hook

  require Logger

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged

  @required_assigns [
    :node_id,
    :lv_process
  ]

  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:temporary_assigns, :handle_async, &handle_async/3)
    |> attach_hook(:temporary_assigns, :handle_info, &handle_info/2)
    |> assign_async_temporary_assigns()
  end

  @spec assign_async_temporary_assigns(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def assign_async_temporary_assigns(socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id

    socket
    |> assign(:temporary_assigns, AsyncResult.loading())
    |> start_async(:fetch_temporary_assigns, fn ->
      NodeStateQueries.fetch_node_temporary_assigns(pid, node_id)
    end)
  end

  defp handle_async(:fetch_temporary_assigns, {:ok, {:ok, temporary_assigns}}, socket) do
    socket
    |> assign(temporary_assigns: AsyncResult.ok(temporary_assigns))
    |> halt()
  end

  defp handle_async(:fetch_temporary_assigns, {:ok, {:error, reason}}, socket) do
    handle_error(reason, socket)
  end

  defp handle_async(:fetch_temporary_assigns, {:exit, reason}, socket) do
    handle_error(reason, socket)
  end

  defp handle_async(_, _, socket), do: {:cont, socket}

  defp handle_info(%StateChanged{}, socket) do
    socket
    |> assign_async_temporary_assigns()
    |> cont()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_error(reason, socket) do
    Logger.error("Failed to fetch temporary assigns: #{inspect(reason)}")

    socket
    |> assign(temporary_assigns: AsyncResult.failed(socket.assigns.temporary_assigns, reason))
    |> halt()
  end
end
