defmodule LiveDebugger.App.Debugger.NodeState.Web.Hooks.TemporaryAssigns do
  @moduledoc """
  This hook is responsible for fetching temporary assigns of specific node.
  """

  use LiveDebugger.App.Web, :hook

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
    |> assign(:temporary_assigns, %{})
    |> assign_async_temporary_assigns()
  end

  @spec assign_async_temporary_assigns(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def assign_async_temporary_assigns(socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id

    socket
    |> assign(:temporary_assigns, %{})
    |> start_async(:fetch_temporary_assigns, fn ->
      NodeStateQueries.fetch_node_temporary_assigns(pid, node_id)
    end)
  end

  defp handle_async(:fetch_temporary_assigns, {:ok, {:ok, temporary_assigns}}, socket) do
    socket
    |> assign(temporary_assigns: temporary_assigns)
    |> halt()
  end

  defp handle_async(:fetch_temporary_assigns, {:ok, {:error, _}}, socket) do
    {:halt, socket}
  end

  defp handle_async(:fetch_temporary_assigns, {:exit, _reason}, socket) do
    {:halt, socket}
  end

  defp handle_info(%StateChanged{}, socket) do
    socket
    |> assign_async_temporary_assigns()
    |> cont()
  end

  defp handle_info(_, socket), do: {:cont, socket}
end
