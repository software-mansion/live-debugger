defmodule LiveDebuggerDev.LiveComponents.ManyAssigns do
  use DevWeb, :live_component

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> ok()
  end

  attr(:rest, :global)

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
