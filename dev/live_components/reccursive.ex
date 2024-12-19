defmodule LiveDebuggerDev.LiveComponents.Reccursive do
  use DevWeb, :live_component

  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:counter, assigns.counter)
    |> then(&{:ok, &1})
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
