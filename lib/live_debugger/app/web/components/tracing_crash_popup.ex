defmodule LiveDebugger.App.Web.Components.TracingCrashPopup do
  @moduledoc """
  Popup component that is shown when the traced LiveView process crashes.

  It assigns `:tracing_enabled?` to the socket, which is used to show or hide the popup.
  It requires subscribing to `Bus` events in the parent LiveView.
  """

  alias LiveDebugger.App.Events.UserRefreshedTrace
  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.DbgKilled
  alias LiveDebugger.Services.CallbackTracer.GenServers.TracingManager

  use LiveDebugger.App.Web, :hook_component

  @impl true
  def init(socket) do
    tracing_enabled? = TracingManager.tracer_started?()

    socket
    |> assign(:tracing_enabled?, tracing_enabled?)
    |> attach_hook(:tracing_crash_popup, :handle_info, &handle_info/2)
    |> attach_hook(:tracing_crash_popup, :handle_event, &handle_event/3)
    |> register_hook(:tracing_crash_popup)
  end

  attr(:tracing_enabled?, :boolean, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <.popup
      id="tracing-disabled-modal"
      title="Tracing Disabled"
      show={not @tracing_enabled?}
      wrapper_class="z-50"
      on_close={nil}
    >
      <div class="flex flex-col gap-4 w-full">
        <p class="text-base text-justify">
          Tracing has been stopped. This may happen when the system is under heavy load or when there's an issue with the tracer.
        </p>
        <p class=" text-base text-justify text-accent-text font-semibold">
          Click the button below to restart tracing and continue debugging.
        </p>
        <div class="flex justify-center mt-2">
          <.button
            phx-click="enable-tracing"
            variant="primary"
          >
            Enable Tracing
          </.button>
        </div>
      </div>
    </.popup>
    """
  end

  defp handle_event("enable-tracing", _, socket) do
    Bus.broadcast_event!(%UserRefreshedTrace{})

    {:halt, assign(socket, :tracing_enabled?, true)}
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp handle_info(%DbgKilled{}, socket) do
    {:halt, assign(socket, :tracing_enabled?, false)}
  end

  defp handle_info(_, socket), do: {:cont, socket}
end
