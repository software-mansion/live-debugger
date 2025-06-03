defmodule LiveDebuggerWeb.Components.Traces.ClearButton do
  use LiveDebuggerWeb, :component

  import Phoenix.LiveView

  alias LiveDebugger.Services.TraceService

  def attach_hook(socket) do
    attach_hook(socket, :clear_button, :handle_event, &handle_event/3)
  end

  def clear_button(assigns) do
    ~H"""
    <.button phx-click="clear-traces" class="flex gap-2" variant="secondary" size="sm">
      <.icon name="icon-trash" class="w-4 h-4" />
      <div class="hidden @[29rem]/traces:block">Clear</div>
    </.button>
    """
  end

  defp handle_event("clear-traces", _, socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id

    TraceService.clear_traces(pid, node_id)

    socket
    |> stream(:existing_traces, [], reset: true)
    |> assign(:traces_empty?, true)
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
