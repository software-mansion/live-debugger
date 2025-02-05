defmodule LiveDebuggerDev.LiveViews.EmbeddedLiveViews do
  use DevWeb, :live_view

  alias LiveDebuggerDev.LiveComponents
  alias LiveDebuggerDev.LiveViews

  def render(assigns) do
    ~H"""
    <div class="p-5">
      <.navbar />
      <.box title="Embedded Live Views [LiveView]" color="blue">
        <%= live_render(@socket, LiveViews.Inner,
          id: "inner",
          session: %{"info" => "Embedded Live View"}
        ) %>

        <.live_component id="conditional" module={LiveComponents.Conditional}>
          <%= live_render(@socket, LiveViews.Inner,
            id: "inner_in_conditional",
            session: %{"info" => "Live View embedded in conditional component"}
          ) %>
        </.live_component>
      </.box>
    </div>
    """
  end
end
