defmodule LiveDebuggerWeb.Components.Traces.ToggleTracingButton do
  @moduledoc """
  This component is responsible for the toggle tracing button.

  It produces switch-tracing event when clicked that can be handled by hook declared via `init/1`.
  This component is using `TracingFuse` hook to switch the tracing.
  """

  use LiveDebuggerWeb, :hook_component

  alias LiveDebuggerWeb.Hooks.Traces.TracingFuse

  import Phoenix.LiveView

  @separator %{id: "separator"}

  @doc """
  Initializes the toggle tracing button by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_hook!(:tracing_fuse)
    |> check_assigns!(:tracing_started?)
    |> check_assigns!(:traces_empty?)
    |> attach_hook(:toggle_tracing_button, :handle_event, &handle_event/3)
    |> register_hook(:toggle_tracing_button)
  end

  @doc """
  Renders the toggle tracing button.
  It produces `switch-tracing` event when clicked that can be handled by hook declared via `init/1`.
  """

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

  defp handle_event("switch-tracing", _, socket) do
    socket = TracingFuse.switch_tracing(socket)

    if socket.assigns.tracing_started? and !socket.assigns.traces_empty? do
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
