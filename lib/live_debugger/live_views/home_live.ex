defmodule LiveDebugger.LiveViews.HomeLive do
  use LiveDebuggerWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.h1 class="m-5 mb-6">Hello from LiveDebugger</.h1>
    """
  end
end
