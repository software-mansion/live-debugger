defmodule LiveDebugger.LiveViews.HelloLive do
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :current_pid, inspect(self()))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Hello, from <%= @current_pid %></h1>
    """
  end
end
