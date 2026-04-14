defmodule LiveDebugger.App.Web.Components.TracingCrashPopup do
  @moduledoc """
  Popup component that is shown when the tracer process crashes or is killed.
  Use it inside `LiveDebugger.App.Web.Components.Navbar` to show loading state.

  It assigns `:tracing_enabled?` to the socket, which is used to show or hide the popup.
  It requires subscribing to `Bus` events in the parent LiveView.
  """

  alias LiveDebugger.App.Events.UserRefreshedTrace
  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.DbgKilled
  alias LiveDebugger.Services.CallbackTracer.Events.DbgStarted
  alias LiveDebugger.Services.CallbackTracer.GenServers.TracingManager
  alias Phoenix.LiveView.AsyncResult

  use LiveDebugger.App.Web, :hook_component

  @tracing_statuses [:started, :stopped, :starting]

  @impl true
  def init(socket) do
    socket
    |> assign_async(:tracing_status, fn ->
      {:ok, %{tracing_status: TracingManager.tracer_started?() |> initial_status()}}
    end)
    |> attach_hook(:tracing_crash_popup, :handle_info, &handle_info/2)
    |> attach_hook(:tracing_crash_popup, :handle_event, &handle_event/3)
    |> register_hook(:tracing_crash_popup)
  end

  attr(:tracing_status, AsyncResult, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <.async_result :let={tracing_status} assign={@tracing_status}>
      <.popup
        id="tracing-disabled-modal"
        title="Tracing Disabled"
        show={not tracing_started?(tracing_status)}
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
              disabled={tracing_status == :starting}
            >
              Enable Tracing
            </.button>
          </div>
        </div>
      </.popup>
    </.async_result>
    """
  end

  defp handle_event("enable-tracing", _, socket) do
    Bus.broadcast_event!(%UserRefreshedTrace{})

    {:halt, assign(socket, :tracing_status, AsyncResult.ok(:starting))}
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp handle_info(%DbgKilled{}, socket) do
    {:halt, assign(socket, :tracing_status, AsyncResult.ok(:stopped))}
  end

  defp handle_info(%DbgStarted{}, socket) do
    {:halt, assign(socket, :tracing_status, AsyncResult.ok(:started))}
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp tracing_started?(tracing_status) when tracing_status in @tracing_statuses do
    case tracing_status do
      :started -> true
      _ -> false
    end
  end

  defp initial_status(started?), do: if(started?, do: :started, else: :stopped)
end
