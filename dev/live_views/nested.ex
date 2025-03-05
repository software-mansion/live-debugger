defmodule LiveDebuggerDev.LiveViews.Nested do
  use DevWeb, :live_view

  alias LiveDebuggerDev.LiveComponents
  alias LiveDebuggerDev.LiveViews

  def render(assigns) do
    ~H"""
    <div class="p-5">
      <.navbar />
      <.box title="Nested Live Views [LiveView]" color="blue">
        <%= live_render(@socket, LiveViews.Simple, id: "inner") %>
      </.box>
    </div>
    """
  end
end
