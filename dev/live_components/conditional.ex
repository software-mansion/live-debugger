defmodule LiveDebuggerDev.LiveComponents.Conditional do
  @moduledoc false
  use DevWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, :show_child?, false)}
  end

  attr(:id, :string, default: nil)
  slot(:inner_block)

  def render(assigns) do
    ~H"""
    <div>
      <.box id={@id} title="Conditional [LiveComponent]" color="orange">
        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-1">
            <.button id={@id <> "-button"} phx-click="show_child" phx-target={@myself} color="orange">
              Show
            </.button>

            <span>child LiveComponent below</span>
          </div>
          <div :if={@show_child?}>
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </.box>
    </div>
    """
  end

  def handle_event("show_child", _, socket) do
    {:noreply, assign(socket, :show_child?, not socket.assigns.show_child?)}
  end
end
