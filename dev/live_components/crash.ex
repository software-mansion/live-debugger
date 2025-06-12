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

  def handle_event("crash", _, socket) do
    raise "Exception in handle_event"
    {:noreply, socket}
  end
end
