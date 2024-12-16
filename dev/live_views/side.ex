defmodule LiveDebuggerDev.LiveViews.Side do
  use DevWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="p-5">
      <.link navigate="/" class="text-blue-500 underline">Back to main</.link>
    </div>
    """
  end
end
