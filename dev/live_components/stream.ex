defmodule LiveDebuggerDev.LiveComponents.StreamComponent do
  use DevWeb, :live_component

  def update(assigns, socket) do
    items = [
      %{id: "item-1", name: "first"},
      %{id: "item-2", name: "second"},
      %{id: "item-3", name: "third"}
    ]

    socket
    |> assign(assigns)
    |> stream(:component_items, items)
    |> then(&{:ok, &1})
  end

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Component with stream" color="yellow">
        <.button id="create-item-in-component" phx-click="create_another_item">
          Create Item in Component
        </.button>
      </.box>
    </div>
    """
  end
end
