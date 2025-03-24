defmodule LiveDebuggerDev.LiveViews.Embedded do
  use Phoenix.LiveView, layout: {LiveDebuggerDev.Layout, :embedded}

  import LiveDebuggerDev.Components
  import Phoenix.HTML
  import LiveDebuggerWeb.Helpers
  import LiveDebuggerDev.Helpers

  def render(assigns) do
    ~H"""
    <.box title="Live Session [LiveView]" color="blue">
      <%= live_render(@socket, LiveDebuggerDev.LiveViews.Simple, id: "live_session_inner") %>
    </.box>
    """
  end
end
