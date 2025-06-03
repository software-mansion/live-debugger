defmodule LiveDebuggerWeb.Components.Traces.ToggleTracingButton do
  use LiveDebuggerWeb, :component

  alias LiveDebuggerWeb.Helpers.TracingHelper

  import Phoenix.LiveView

  @separator %{id: "separator"}

  attr(:tracing_started?, :boolean, required: true)

  def toggle_tracing_button(assigns) do
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

  def attach_hook(socket) do
    attach_hook(socket, :toggle_tracing_button, :handle_event, &handle_event/3)
  end

  defp handle_event("switch-tracing", _, socket) do
    socket = TracingHelper.switch_tracing(socket)

    if socket.assigns.tracing_helper.tracing_started? and !socket.assigns.traces_empty? do
      socket
      |> stream_delete(:existing_traces, @separator)
      |> stream_insert(:existing_traces, @separator, at: 0)
    else
      socket
    end
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
