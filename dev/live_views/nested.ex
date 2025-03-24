defmodule LiveDebuggerDev.LiveViews.Nested do
  use DevWeb, :live_view

  alias LiveDebuggerDev.LiveViews

  def render(assigns) do
    ~H"""
    <.box title="Nested Live Views [LiveView]" color="blue">
      <%= live_render(@socket, LiveViews.Simple, id: "inner") %>
    </.box>
    """
  end
end
