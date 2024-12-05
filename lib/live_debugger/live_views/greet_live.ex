defmodule LiveDebugger.LiveViews.GreetLive do
  use Phoenix.LiveView

  @impl true
  def mount(params, _session, socket) do
    {:ok, assign(socket, :name, params["name"])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Greetings, <%= @name %>!</h1>
    """
  end
end
