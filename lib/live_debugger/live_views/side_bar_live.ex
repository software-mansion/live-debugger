defmodule LiveDebugger.LiveViews.SidebarLive do
  alias Phoenix.PubSub
  use LiveDebuggerWeb, :live_view

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
    |> assign_base_url()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <button phx-click="select_node">Sidebar</button>
    """
  end

  @impl true
  def handle_info({:new_trace, trace}, socket) do
    dbg(trace.function)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_node", _, socket) do
    socket
    |> push_patch(to: "#{socket.assigns.base_url}/dupa")
    |> noreply()
  end

  defp assign_base_url(socket) do
    assign(socket, :base_url, "/#{socket.assigns.socket_id}")
  end
end
