defmodule LiveDebuggerDev.LiveComponents.Crash do
  @moduledoc false
  use DevWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Crash [LiveComponent]" color="red">
        <.button phx-click="crash" color="red" phx-target={@myself}>Crash</.button>
        <.button phx-click="crash_after_sleep" color="red" phx-target={@myself}>
          Crash after 4s
        </.button>
      </.box>
    </div>
    """
  end

  def handle_event("crash_after_sleep", _, _) do
    Process.sleep(4000)
    raise "Exception in handle_event"
  end

  def handle_event("crash", _, _) do
    raise "Exception in handle_event"
  end
end
