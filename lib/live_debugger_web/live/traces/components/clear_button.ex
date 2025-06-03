defmodule LiveDebuggerWeb.Live.Traces.Components.ClearButton do
  @moduledoc """
  This component is used to clear the traces.
  It produces the `clear-traces` event that can be handled by the hook provided in the `init/1` function.
  """

  use LiveDebuggerWeb, :hook_component

  alias LiveDebugger.Services.TraceService

  @doc """
  Initializes the component by checking the assigns and streams and attaching the hook to the socket.
  The hook is used to handle the `clear-traces` event.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(:lv_process)
    |> check_assigns!(:node_id)
    |> check_assigns!(:traces_empty?)
    |> check_streams!(:existing_traces)
    |> attach_hook(:clear_button, :handle_event, &handle_event/3)
    |> register_hook(:clear_button)
  end

  @doc """
  Renders the clear button.
  It produces the `clear-traces` event that can be handled by the hook provided in the `init/1` function.
  """
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
