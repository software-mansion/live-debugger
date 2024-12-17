defmodule LiveDebuggerDev.LiveComponents.Reccursive do
  use Phoenix.LiveComponent

  import LiveDebuggerDev.Components

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    assigns = assign(assigns, :render?, assigns.counter > 0)

    ~H"""
    <div>
      <.box title={"Reccursive (#{@counter}) [LiveComponent]"} color="purple">
        <.live_component :if={@render?} module={__MODULE__} id={@id <> "|"} counter={@counter - 1} />
      </.box>
    </div>
    """
  end
end
