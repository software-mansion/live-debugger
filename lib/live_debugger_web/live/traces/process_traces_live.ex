defmodule LiveDebuggerWeb.Live.Traces.ProcessTracesLive do
  use LiveDebuggerWeb, :live_view

  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebuggerWeb.Live.Traces.Components
  alias LiveDebuggerWeb.Live.Traces.Helpers
  alias LiveDebuggerWeb.Live.Traces.Hooks

  @page_size 25
  @live_stream_limit 128

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true)
  attr(:params, :map, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "id" => assigns.id,
      "params" => assigns.params,
      "parent_pid" => self()
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: @class}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    parent_pid = session["parent_pid"]

    if connected?(socket) do
      parent_pid
      |> PubSubUtils.params_changed_topic()
      |> PubSubUtils.subscribe!()
    end

    socket
    |> assign(:id, session["id"])
    |> assign(:parent_pid, session["parent_pid"])
    |> assign(:lv_process, session["lv_process"])
    |> stream(:existing_traces, [], reset: true)
    |> assign(:existing_traces_status, :loading)
    |> assign(:tracing_started?, false)
    |> assign(:trace_callback_running?, false)
    |> assign(:traces_empty?, true)
    |> assign(:displayed_trace, nil)
    |> assign(:traces_continuation, nil)
    |> Helpers.assign_default_filters()
    |> Helpers.assign_current_filters()
    |> Components.LoadMoreButton.init()
    |> Hooks.TracingFuse.init()
    |> Hooks.ExistingTraces.init(@page_size)
    |> Hooks.NewTraces.init(@live_stream_limit)
    |> Components.ToggleTracingButton.init()
    |> Components.Stream.init()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-full @container/traces flex flex-1">
      <.section title="Callback traces" id="traces" inner_class="mx-0 my-4 px-4" class="flex-1">
        <:right_panel>
          <div class="flex gap-2 items-center">
            <Components.ToggleTracingButton.toggle_tracing_button tracing_started?={@tracing_started?} />
            <%!-- <Components.RefreshButton.refresh_button :if={not @tracing_started?} /> --%>
            <%!-- <Components.ClearButton.clear_button :if={not @tracing_started?} /> --%>
          </div>
        </:right_panel>
        <div class="w-full h-full">
          <Components.Stream.traces_stream
            id={@id}
            existing_traces_status={@existing_traces_status}
            existing_traces={@streams.existing_traces}
          />
          <Components.LoadMoreButton.load_more_button
            :if={not @tracing_started?}
            traces_continuation={@traces_continuation}
          />
        </div>
      </.section>
      <Components.trace_fullscreen id="trace-fullscreen" trace={@displayed_trace} />
    </div>
    """
  end
end
