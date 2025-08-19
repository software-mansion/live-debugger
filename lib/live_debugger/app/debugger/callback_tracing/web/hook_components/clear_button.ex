defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.ClearButton do
  @moduledoc """
  This component is used to clear the traces.
  It produces `clear-traces` event handled by hook added via `init/1`.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.API.TracesStorage

  @required_assigns [:lv_process, :traces_empty?, :node_id]

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> check_stream!(:existing_traces)
    |> attach_hook(:clear_button, :handle_event, &handle_event/3)
    |> register_hook(:clear_button)
  end

  attr(:label_class, :string, default: "")

  @impl true
  def render(assigns) do
    ~H"""
    <.button
      phx-click="clear-traces"
      aria-label="Clear traces"
      class="flex gap-2"
      variant="secondary"
      size="sm"
    >
      <.icon name="icon-trash" class="w-4 h-4" />
      <div class={[@label_class, "ml-1"]}>
        Clear
      </div>
    </.button>
    """
  end

  defp handle_event("clear-traces", _, socket) do
    TracesStorage.clear!(socket.assigns.lv_process.pid, socket.assigns.node_id)

    socket
    |> stream(:existing_traces, [], reset: true)
    |> assign(:traces_empty?, true)
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
