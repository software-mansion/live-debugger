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
    <TraceSettings.maybe_add_tooltip
      display_mode={@display_mode}
      id="clear-tooltip"
      content="Clear"
      position="top-center"
    >
      <.button
        phx-click="clear-traces"
        aria-label="Clear traces"
        class={[
          "flex !w-7 !h-7 px-[0.2rem] py-[0.2rem] items-center justify-center",
          @label_class,
          @display_mode == :dropdown && "!w-full !border-none !h-full"
        ]}
        variant="secondary"
        size="sm"
      >
        <TraceSettings.action_icon display_mode={@display_mode} icon="icon-trash" label="Clear" />
      </.button>
    </TraceSettings.maybe_add_tooltip>
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
