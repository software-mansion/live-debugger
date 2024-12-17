defmodule LiveDebuggerDev.LiveComponents.LiveComponentWithVeryVeryLongName do
  use Phoenix.LiveComponent

  import LiveDebuggerDev.Components

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Very Long Name [LiveComponent]" color="red"></.box>
    </div>
    """
  end
end
