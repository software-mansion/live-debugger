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
      <.box title="Component with stream" color="yellow"></.box>
    </div>
    """
  end
end
