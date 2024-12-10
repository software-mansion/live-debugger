defmodule LiveDebuggerDev.LiveComponents.Name do
  use Phoenix.LiveComponent

  import LiveDebuggerDev.Components

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, name: assigns.name)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Name [LiveComponent]" color="red">
        <div>Name from parent: <span class="italic">{@name}</span></div>
      </.box>
    </div>
    """
  end
end
