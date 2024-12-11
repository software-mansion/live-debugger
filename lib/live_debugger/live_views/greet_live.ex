defmodule LiveDebugger.LiveViews.GreetLive do
  use LiveDebuggerWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    {:ok, assign(socket, :name, params["name"])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.container max_width="lg">
      Greetings, {@name}! <.icon name="hero-home" class="text-gray-700 dark:text-gray-300" />
    </.container>
    """
  end
end
