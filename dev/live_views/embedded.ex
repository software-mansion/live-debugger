defmodule LiveDebuggerDev.LiveViews.Embedded do
  use Phoenix.LiveView, layout: {LiveDebuggerDev.Layout, :embedded}

  import LiveDebuggerDev.Components

  def render(assigns) do
    assigns = assign(assigns, id: "embedded")

    ~H"""
    <.box title="Live Session [LiveView]" color="blue">
      <.live_component module={LiveDebuggerDev.LiveComponents.Wrapper} id={"#{@id}_wrapper"}>
        <%= live_render(@socket, LiveDebuggerDev.LiveViews.Nested,
          id: "#{@id}_wrapper_inner",
          session: %{}
        ) %>
      </.live_component>
      <LiveDebuggerDev.LiveViews.Simple.live_render
        socket={@socket}
        id={"#{@id}_live_session_inner_2"}
      />
    </.box>
    """
  end
end
