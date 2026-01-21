defmodule LiveDebuggerDev.LiveComponents.ManyAssigns do
  use DevWeb, :live_component

  def mount(socket) do
    socket =
      socket
      |> assign(temp: "some value")

    {:ok, socket, temporary_assigns: [temp: nil]}
  end

  def update(assigns, socket) do
    socket
    |> assign(Map.merge(assigns, very_long_assigns_map()))
    |> assign(temp: "some value")
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
