defmodule LiveDebuggerDev.LiveComponents.Conditional do
  use DevWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, :show_child?, false)}
  end

  slot(:inner_block)

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Conditional [LiveComponent]" color="orange">
        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-1">
            <button
              phx-click="show_child"
              phx-target={@myself}
              class="bg-orange-500 text-white py-1 px-2 rounded"
            >
              Show
            </button>

            <span>child LiveComponent below</span>
          </div>
          <div :if={@show_child?}>
            {render_slot(@inner_block)}
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
