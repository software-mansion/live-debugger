defmodule LiveDebuggerDev.LiveViews.Embedded do
  use Phoenix.LiveView, layout: {LiveDebuggerDev.Layout, :embedded}

  import LiveDebuggerDev.Components

  def render(assigns) do
    ~H"""
    <.box title="Live Session [LiveView]" color="blue">
      <.live_component module={LiveDebuggerDev.LiveComponents.Wrapper} id="wrapper">
        <%= live_render(@socket, LiveDebuggerDev.LiveViews.Simple, id: "live_session_inner_1") %>
      </.live_component>
      <%= live_render(@socket, LiveDebuggerDev.LiveViews.Simple, id: "live_session_inner_2") %>
    </.box>
    """
  end
end
