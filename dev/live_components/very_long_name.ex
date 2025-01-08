defmodule LiveDebuggerDev.LiveComponents.LiveComponentWithVeryVeryLongName do
  use DevWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Very Long Name [LiveComponent]" color="gray"></.box>
    </div>
    """
  end
end
