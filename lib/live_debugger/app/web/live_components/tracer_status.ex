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

  @documentation_url "https://hexdocs.pm/live_debugger/config.html#maximum-memory-size"

  @impl true
  def mount(socket) do
    socket
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
        <.tracer_crash_info
          :if={!started?}
          restarting?={@restarting?}
          myself={@myself}
        />
        <.tracer_crashed_popup
          :if={!started?}
          id={@id <> "-crashed_popup"}
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
    |> push_event("set_dismissed", %{})
    |> noreply()
  end

  def handle_event("restart_tracing", _params, socket) do
    Bus.broadcast_event!(%UserRefreshedTrace{})

    socket
    |> assign(:restarting?, true)
    |> noreply()
  end

  defp maybe_reset_on_started(socket, %AsyncResult{ok?: true, result: true}) do
    assign(socket, :restarting?, false)
  end

  defp maybe_reset_on_started(socket, _), do: socket

  attr(:restarting?, :boolean, required: true)
  attr(:myself, :any, required: true)

  defp tracer_crash_info(assigns) do
    ~H"""
    <div class="bg-error-bg border-b border-error-border text-error-text flex items-center justify-center gap-2 py-2 px-4 text-xs">
      <.icon name="icon-exclamation-circle" class="w-4 h-4 inline-block align-middle text-error-icon" />
      <div><b>Tracer crashed </b> - restart to enable core functionalities</div>
      <button
        phx-click="restart_tracing"
        phx-target={@myself}
        disabled={@restarting?}
        class={[
          "inline-flex items-center gap-1.5 py-1.5 px-2",
          "rounded border-2 border-error-text",
          "bg-error-bg hover:bg-error-text",
          "text-xs font-semibold text-error-text hover:text-error-bg",
          "disabled:opacity-50 disabled:pointer-events-none"
        ]}
      >
        <.spinner :if={@restarting?} size="xs" /> Restart Tracing
      </button>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:restarting?, :boolean, required: true)
  attr(:myself, :any, required: true)

  defp tracer_crashed_popup(assigns) do
    assigns = assign(assigns, :documentation_url, @documentation_url)

    ~H"""
    <div id={@id} phx-hook="TracerPopupDismissed" phx-target={@myself} class="hidden">
      <.popup
        id={@id <> "-popup"}
        title="Tracer Crashed"
        on_close={JS.push("dismiss", target: @myself)}
      >
        <div class="flex flex-col gap-4">
          <div class="flex items-start gap-3 border border-error-border bg-error-bg rounded p-3">
            <.icon
              name="icon-exclamation-circle"
              class="w-4 h-4 text-error-icon flex-shrink-0 mt-0.5"
            />
            <div class="flex flex-col gap-1">
              <p class="text-xs font-semibold text-primary-text">
                The tracer process has crashed
              </p>
              <p class="text-xs text-secondary-text leading-relaxed">
                LiveDebugger's tracer has stopped unexpectedly.
              </p>
            </div>
          </div>

          <div class="px-3">
            Core functionalities like <b>Assigns</b>
            and <b>Callback Tracing</b>
            won't have newest information and may be misleading.
          </div>
          <div class="px-3">
            This may be caused by <b>debugged application</b>
            having an excessive number of traces with huge sizes - LiveDebugger has a max heap size set for tracing. See
            <.link
              href={@documentation_url}
              target="_blank"
              class="text-link-primary hover:text-link-primary-hover"
            >
              configuration
            </.link>
          </div>

          <div class="flex justify-center">
            <.button
              phx-click="restart_tracing"
              phx-target={@myself}
              disabled={@restarting?}
              class="flex items-center gap-2"
            >
              <.spinner
                :if={@restarting?}
                size="xs"
                class="text-button-primary-content"
              /> Restart Tracing
            </.button>
          </div>
        </div>
      </.popup>
    </div>
    """
  end
end
