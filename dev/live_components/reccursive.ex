defmodule LiveDebuggerDev.LiveComponents.Reccursive do
  use Phoenix.LiveComponent

  import LiveDebuggerDev.Components

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  attr(:id, :string, required: true)
  attr(:counter, :integer, required: true)

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
