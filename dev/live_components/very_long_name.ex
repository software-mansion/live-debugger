defmodule LiveDebuggerDev.LiveComponents.LiveComponentWithVeryVeryLongName do
  use Phoenix.LiveComponent

  import LiveDebuggerDev.Components

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Very Long Name [LiveComponent]" color="gray"></.box>
    </div>
    """
  end
end
