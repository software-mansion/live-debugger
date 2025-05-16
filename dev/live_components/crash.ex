defmodule LiveDebuggerDev.LiveComponents.Crash do
  use DevWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Crash [LiveComponent]" color="red">
        <.button phx-click="crash" color="red" phx-target={@myself}>Crash</.button>
      </.box>
    </div>
    """
  end
end
