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

  @impl true
  def render(assigns) do
    ~H"""
    <.button phx-click="switch-tracing" class="flex gap-2" size="sm">
      <div class="flex gap-1.5 items-center w-12">
        <%= if @tracing_started? do %>
          <.icon name="icon-stop" class="w-4 h-4" />
          <div>Stop</div>
        <% else %>
          <.icon name="icon-play" class="w-3.5 h-3.5" />
          <div>Start</div>
        <% end %>
      </div>
    </.button>
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
