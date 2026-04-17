defmodule LiveDebugger.App.Web.LiveComponents.TracerStatus do
  @moduledoc """
  This LiveComponent needs `LiveDebugger.App.Web.Hooks.TracerStatus` to work.

  Displays a modal popup when the tracer has crashed (i.e. `:tracer_started?` is `AsyncResult.ok(false)`).
  The popup can be dismissed by clicking the X button.
  """
  use LiveDebugger.App.Web, :live_component

  alias Phoenix.LiveView.AsyncResult
  alias Phoenix.LiveView.JS
  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.UserRefreshedTrace

  @impl true
  def mount(socket) do
    socket
    |> assign(:dismissed?, false)
    |> assign(:restarting?, false)
    |> ok()
  end

  @impl true
  def update(%{tracer_started?: tracer_started?} = assigns, socket) do
    socket
    |> assign(:tracer_started?, tracer_started?)
    |> assign(:id, assigns.id)
    |> maybe_reset_on_started(tracer_started?)
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:tracer_started?, AsyncResult, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.async_result :let={started?} assign={@tracer_started?}>
        <:loading>
          <.status_dot
            status={:warning}
            pulse?={true}
            tooltip={
              %{
                content: "Fetching Tracer Status",
                position: "bottom"
              }
            }
          />
        </:loading>
        <:failed>
          <div class="flex items-center gap-1">
            <.status_dot
              status={:error}
              pulse?={true}
              tooltip={
                %{
                  content: "Error Fetching Tracer Status. Click to retry",
                  position: "bottom"
                }
              }
              phx-click="refetch"
              phx-target={@myself}
            />
          </div>
        </:failed>
        <.tracer_crash_info
          :if={!started?}
          restarting?={@restarting?}
          myself={@myself}
        />
        <.tracer_crashed_popup
          :if={!started?}
          dismissed?={@dismissed?}
          restarting?={@restarting?}
          myself={@myself}
        />
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("dismiss", _params, socket) do
    socket
    |> assign(:dismissed?, true)
    |> noreply()
  end

  def handle_event("restart_tracing", _params, socket) do
    Bus.broadcast_event!(%UserRefreshedTrace{})

    socket
    |> assign(:restarting?, true)
    |> noreply()
  end

  def handle_event("refetch", _params, socket) do
    LiveDebugger.App.Web.Hooks.TracerStatus.refresh_tracer_status()

    {:noreply, socket}
  end

  defp maybe_reset_on_started(socket, %AsyncResult{ok?: true, result: true}) do
    socket
    |> assign(:dismissed?, false)
    |> assign(:restarting?, false)
  end

  defp maybe_reset_on_started(socket, _), do: socket

  attr(:restarting?, :boolean, required: true)
  attr(:myself, :any, required: true)

  defp tracer_crash_info(assigns) do
    ~H"""
    <div class="bg-error-bg border-b border-error-border text-error-text flex items-center justify-center py-2 px-4 text-xs">
      <.icon name="icon-exclamation-circle" class="w-3 h-3 inline-block mr-1 align-middle" />
      <b>Tracer crashed</b>
      - restart to enable core functionalities
      <button
        phx-click="restart_tracing"
        phx-target={@myself}
        disabled={@restarting?}
        class="inline-flex items-center gap-1.5 ml-2 rounded text-xs font-semibold py-1.5 px-2 bg-error-border text-white hover:opacity-90 disabled:opacity-50 disabled:pointer-events-none"
      >
        <.spinner :if={@restarting?} size="xs" /> Restart Tracing
      </button>
    </div>
    """
  end

  attr(:dismissed?, :boolean, required: true)
  attr(:restarting?, :boolean, required: true)
  attr(:myself, :any, required: true)

  defp tracer_crashed_popup(assigns) do
    ~H"""
    <LiveDebugger.App.Web.Components.popup
      id="tracer-crashed-popup"
      title="Tracer Crashed"
      show={!@dismissed?}
      on_close={JS.push("dismiss", target: @myself)}
    >
      <div class="flex flex-col gap-4">
        <div class="flex items-start gap-3 border border-error-border bg-error-bg rounded p-3">
          <LiveDebugger.App.Web.Components.icon
            name="icon-exclamation-circle"
            class="w-4 h-4 text-error-icon flex-shrink-0 mt-0.5"
          />
          <div class="flex flex-col gap-1">
            <p class="text-xs font-semibold text-primary-text">
              The tracer process has crashed
            </p>
            <p class="text-xs text-secondary-text leading-relaxed">
              LiveDebugger's tracer has stopped unexpectedly. Core functionalities won't work until restart.
            </p>
          </div>
        </div>

        <div class="flex justify-center">
          <LiveDebugger.App.Web.Components.button
            phx-click="restart_tracing"
            phx-target={@myself}
            disabled={@restarting?}
            class="flex items-center gap-2"
          >
            <LiveDebugger.App.Web.Components.spinner
              :if={@restarting?}
              size="xs"
              class="text-button-primary-content"
            /> Restart Tracing
          </LiveDebugger.App.Web.Components.button>
        </div>
      </div>
    </LiveDebugger.App.Web.Components.popup>
    """
  end
end
