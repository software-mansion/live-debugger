defmodule LiveDebuggerDev.LiveViews.Simple do
  use DevWeb, :live_view

  def render(assigns) do
    ~H"""
    <.box title="Simple [LiveView]" color="yellow">
      <.live_component id="conditional" module={LiveDebuggerDev.LiveComponents.Conditional}>
        <.live_component
          id="conditional-many-assigns"
          module={LiveDebuggerDev.LiveComponents.ManyAssigns}
        />
      </.live_component>
    </.box>
    """
  end
end
