defmodule LiveDebuggerWeb.WindowDashboardLive do
  use LiveDebuggerWeb, :live_view

  @impl true
  def mount(%{"transport_pid" => _transport_pid}, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>Window Dashboard</div>
    """
  end
end
