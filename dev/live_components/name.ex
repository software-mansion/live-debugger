defmodule LiveDebuggerDev.LiveComponents.Name do
  use DevWeb, :live_component

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
