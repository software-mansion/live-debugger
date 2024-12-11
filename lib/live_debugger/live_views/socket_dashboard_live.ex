defmodule LiveDebugger.LiveViews.SocketDashboardLive do
  use LiveDebuggerWeb, :live_view

  @impl true
  def mount(%{"socket_id" => socket_id}, _session, socket) do
    {:ok, assign(socket, :socket_id, socket_id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.container max_width="full">
      Monitored socket: <span class="text-blue-500">{@socket_id}</span>
    </.container>
    """
  end
end
