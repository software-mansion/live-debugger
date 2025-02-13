defmodule LiveDebugger.LiveViews.SidebarLive do
  use LiveDebuggerWeb, :live_view

  require Logger

  alias Phoenix.PubSub
  alias LiveDebugger.Services.ChannelService

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)
  attr(:node_id, :any, required: true)

  def live_render(assigns) do
    session = %{
      "socket_id" => assigns.socket_id,
      "node_id" => assigns.node_id,
      "pid" => assigns.pid
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__, id: @id, session: @session) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    socket_id = session["socket_id"]
    PubSub.subscribe(LiveDebugger.PubSub, "#{socket_id}/*/tree_updated")

    socket
    |> assign(pid: session["pid"])
    |> assign(socket_id: session["socket_id"])
    |> assign(node_id: session["node_id"])
    |> assign(base_url: "/#{session["socket_id"]}")
    |> assign(hidden?: true)
    |> assign_async_tree()
    |> ok()
  end

  @impl true
  def render(assigns) do
    dbg(assigns.tree)

    ~H"""
    <button phx-click="select_node">Sidebar</button>
    """
  end

  @impl true
  def handle_info({:new_trace, trace}, socket) do
    dbg(trace.function)
    {:noreply, socket}
  end

  defp assign_async_tree(socket) do
    pid = socket.assigns.pid

    assign_async(socket, :tree, fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
           {:ok, tree} <- ChannelService.build_tree(channel_state) do
        {:ok, %{tree: tree}}
      else
        error -> handle_error(error, pid, "Failed to build tree: ")
      end
    end)
  end

  defp handle_error({:error, :not_alive} = error, pid, _) do
    Logger.info("Process #{inspect(pid)} is not alive")
    error
  end

  defp handle_error(error, _, error_message) do
    Logger.error(error_message <> inspect(error))
    error
  end
end
