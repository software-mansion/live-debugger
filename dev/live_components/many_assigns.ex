defmodule LiveDebuggerDev.LiveComponents.ManyAssigns do
  use DevWeb, :live_component

  def update(_assigns, socket) do
    socket
    |> assign(very_long_assigns_map())
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Many Assigns [LiveComponent]" color="teal">
        <div></div>
      </.box>
    </div>
    """
  end
end
