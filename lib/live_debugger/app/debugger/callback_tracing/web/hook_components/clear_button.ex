defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.ClearButton do
  @moduledoc """
  This component is used to clear the traces.
  It produces `clear-traces` event handled by hook added via `init/1`.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.API.TracesStorage
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Components.TraceSettings

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
  attr(:display_mode, :atom, required: true, values: [:normal, :dropdown])

  @impl true
  def render(assigns) do
    ~H"""
    <.button
      phx-click="clear-traces"
      aria-label="Clear traces"
      class={[
        "flex gap-2",
        @label_class,
        @display_mode == :dropdown && "!w-full !border-none text-primary-text"
      ]}
      variant="secondary"
      size="sm"
    >
      <%= if @display_mode == :normal do %>
        <.tooltip id="clear-tooltip" content="Clear">
          <.icon name="icon-trash" class="w-4 h-4" />
        </.tooltip>
      <% else %>
        <TraceSettings.dropdown_item icon="icon-trash" label="Clear" />
      <% end %>
    </.button>
    """
  end

  defp handle_event("clear-traces", _, socket) do
    TracesStorage.clear!(socket.assigns.lv_process.pid, socket.assigns.node_id)
    LiveDebugger.App.Web.LiveComponents.LiveDropdown.close("tracing-options-dropdown")

    socket
    |> stream(:existing_traces, [], reset: true)
    |> assign(:traces_empty?, true)
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
