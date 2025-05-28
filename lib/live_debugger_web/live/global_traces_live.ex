defmodule LiveDebuggerWeb.GlobalTracesLive do
  use LiveDebuggerWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Global Traces</h1>
    </div>
    """
  end
end
