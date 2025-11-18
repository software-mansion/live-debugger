defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.ToggleTracingButton do
  @moduledoc """
  This component is responsible for the toggle tracing button.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks

  @separator HookComponents.Stream.separator_stream_element()

  @required_assigns [:tracing_started?, :traces_empty?]

  @impl true
  def init(socket) do
    socket
    |> check_hook!(:tracing_fuse)
    |> check_assigns!(@required_assigns)
    |> attach_hook(:toggle_tracing_button, :handle_event, &handle_event/3)
    |> register_hook(:toggle_tracing_button)
  end

  attr(:tracing_started?, :boolean, required: true)
  attr(:lv_process_alive?, :boolean, default: true)

  @impl true
  def render(assigns) do
    ~H"""
    <.tooltip
      id="tracing-tooltip"
      content={if @tracing_started?, do: "Stop", else: "Start"}
      position="top-center"
    >
      <.button phx-click="switch-tracing" class="flex gap-2" size="sm" disabled={!@lv_process_alive?}>
        <.icon name={if @tracing_started?, do: "icon-stop", else: "icon-play"} class="w-4 h-4" />
      </.button>
    </.tooltip>
    """
  end

  defp handle_event("switch-tracing", _, socket) do
    socket
    |> Hooks.TracingFuse.switch_tracing()
    |> case do
      %{assigns: %{tracing_started?: true, traces_empty?: false}} = socket ->
        socket
        |> stream_delete(:existing_traces, @separator)
        |> stream_insert(:existing_traces, @separator, at: 0)

      socket ->
        socket
    end
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
