defmodule LiveDebugger.LiveViews.SidebarLive do
  use LiveDebuggerWeb, :live_view

  require Logger

  import LiveDebugger.Components.Sidebar

  alias LiveDebugger.Structs.TreeNode
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
    |> hide_sidebar_side_over()
    |> assign_async_tree()
    |> ok()
  end

  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)
  attr(:node_id, :any, required: true)
  attr(:base_url, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-max h-max flex">
      <div class="hidden sm:flex flex-col w-60 min-h-max h-screen bg-primary gap-1 pt-4 p-2 pr-3">
        <.sidebar_label socket={@socket} />
        <.separate_bar />
        <.sidebar_content pid={@pid} socket_id={@socket_id} tree={@tree} node_id={@node_id} />
      </div>
      <div class="flex sm:hidden flex-col gap-2 w-14 pt-4 p-1 h-screen bg-primary items-center justify-start">
        <.link patch="/">
          <.sidebar_icon_button icon="hero-home-solid" />
        </.link>
        <.sidebar_icon_button icon="hero-bars-3" phx-click="show_mobile_content" />
        <.sidebar_slide_over :if={not @hidden?}>
          <:header>
            <.sidebar_label socket={@socket} />
          </:header>
          <.sidebar_content pid={@pid} socket_id={@socket_id} tree={@tree} node_id={@node_id} />
        </.sidebar_slide_over>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select_node", %{"node_id" => node_id}, socket) do
    socket
    |> assign(node_id: TreeNode.id_from_string!(node_id))
    |> push_patch(to: "#{socket.assigns.base_url}/#{node_id}")
    |> hide_sidebar_side_over()
    |> noreply()
  end

  @impl true
  def handle_event("show_mobile_content", _params, socket) do
    socket
    |> show_sidebar_slide_over()
    |> noreply()
  end

  @impl true
  def handle_event("close_mobile_content", _params, socket) do
    socket
    |> hide_sidebar_side_over()
    |> noreply()
  end

  @impl true
  def handle_info({:new_trace, _trace}, socket) do
    socket
    |> assign_async_tree()
    |> noreply()
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

  defp show_sidebar_slide_over(socket) do
    assign(socket, :hidden?, false)
  end

  defp hide_sidebar_side_over(socket) do
    assign(socket, :hidden?, true)
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
