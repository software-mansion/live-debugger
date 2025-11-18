defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.RefreshButton do
  @moduledoc """
  This component is used to refresh the traces.
  It produces `refresh-history` event handled by hook added via `init/1`.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Components.TraceSettings

  @impl true
  def init(socket) do
    socket
    |> check_hook!(:existing_traces)
    |> attach_hook(:refresh_button, :handle_event, &handle_event/3)
    |> register_hook(:refresh_button)
  end

  attr(:label_class, :string, default: "")
  attr(:display_mode, :atom, required: true, values: [:normal, :dropdown])

  @impl true
  def render(assigns) do
    ~H"""
    <TraceSettings.maybe_add_tooltip
      display_mode={@display_mode}
      id="refresh-tooltip"
      content="Refresh"
      position="top-center"
    >
      <.button
        phx-click="refresh-history"
        aria-label="Refresh traces"
        class={[
          "flex gap-2",
          @label_class,
          @display_mode == :dropdown && "!w-full !border-none"
        ]}
        variant="secondary"
        size="sm"
      >
        <TraceSettings.action_icon display_mode={@display_mode} icon="icon-refresh" label="Refresh" />
      </.button>
    </TraceSettings.maybe_add_tooltip>
    """
  end

  defp handle_event("refresh-history", _, socket) do
    LiveDebugger.App.Web.LiveComponents.LiveDropdown.close("tracing-options-dropdown")

    socket
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
