defmodule LiveDebuggerDev.LiveComponents.Send do
  use DevWeb, :live_component

  slot(:inner_block)

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Send [LiveComponent]" color="green">
        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-1">
            <button
              phx-click="send_message"
              phx-target={@myself}
              class="bg-green-500 text-white py-1 px-2 rounded"
            >
              Send
            </button>

            <span>
              a message to parent
            </span>
          </div>
          <div>
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </.box>
    </div>
    """
  end

  def handle_event("send_message", _, socket) do
    send(self(), {:new_datetime, DateTime.utc_now()})
    {:noreply, socket}
  end
end
