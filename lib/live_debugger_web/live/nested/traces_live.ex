defmodule LiveDebuggerWeb.Live.Nested.TracesLive do
  @moduledoc """
  This nested live view displays the traces of a LiveView.
  """

  use LiveDebuggerWeb, :live_view

  require Logger

  import LiveDebuggerWeb.Helpers.NestedLiveViewHelper
  import LiveDebuggerWeb.Helpers.TracesLiveHelper

  import LiveDebuggerWeb.Hooks.Traces.ExistingTraces

  alias LiveDebuggerWeb.Helpers.TracingHelper
  alias LiveDebugger.Structs.TraceDisplay
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.Utils.Parsers
  alias LiveDebuggerWeb.Components.Traces

  @live_stream_limit 128
  @page_size 25

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true)
  attr(:params, :map, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "params" => assigns.params,
      "id" => assigns.id,
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
    lv_process = session["lv_process"]
    parent_pid = session["parent_pid"]

    if connected?(socket) do
      parent_pid
      |> PubSubUtils.params_changed_topic()
      |> PubSubUtils.subscribe!()
    end

    socket
    |> Traces.Stream.attach_hook()
    |> Traces.ToggleTracingButton.attach_hook()
    |> Traces.LoadMoreButton.attach_hook(@page_size)
    |> Traces.ClearButton.attach_hook()
    |> Traces.FiltersDropdown.attach_hook()
    |> assign(:id, session["id"])
    |> assign(:parent_pid, session["parent_pid"])
    |> assign(:lv_process, lv_process)
    |> assign_node_id(session)
    |> assign_default_filters()
    |> reset_current_filters()
    |> assign(:displayed_trace, nil)
    |> assign(:traces_continuation, nil)
    |> assign(:traces_empty?, true)
    |> assign(:trace_callback_running?, false)
    |> TracingHelper.init()
    |> LiveDebuggerWeb.Hooks.Traces.ExistingTraces.attach_hook(@page_size)
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:node_id, :map, required: true)
  attr(:socket_id, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-full @container/traces flex flex-1">
      <.section title="Callback traces" id="traces" inner_class="mx-0 my-4 px-4" class="flex-1">
        <:right_panel>
          <div class="flex gap-2 items-center">
            <Traces.ToggleTracingButton.toggle_tracing_button tracing_started?={
              @tracing_helper.tracing_started?
            } />
            <Traces.refresh_button :if={not @tracing_helper.tracing_started?} />
            <Traces.ClearButton.clear_button :if={not @tracing_helper.tracing_started?} />
            <Traces.FiltersDropdown.filters_dropdown
              :if={not @tracing_helper.tracing_started?}
              node_id={@node_id}
              current_filters={@current_filters}
              default_filters={@default_filters}
            />
          </div>
        </:right_panel>
        <div class="w-full h-full">
          <Traces.Stream.traces_stream
            id={@id}
            existing_traces_status={@existing_traces_status}
            existing_traces={@streams.existing_traces}
          />
          <Traces.LoadMoreButton.load_more_button
            :if={not @tracing_helper.tracing_started?}
            traces_continuation={@traces_continuation}
          />
        </div>
      </.section>
      <Traces.trace_fullscreen id="trace-fullscreen" trace={@displayed_trace} />
    </div>
    """
  end

  @impl true
  def handle_info({:new_trace, trace}, socket) do
    socket
    |> TracingHelper.check_fuse()
    |> case do
      {:ok, socket} ->
        trace_display = TraceDisplay.from_trace(trace, true)

        socket
        |> stream_insert(:existing_traces, trace_display, at: 0, limit: @live_stream_limit)
        |> assign(traces_empty?: false)
        |> assign(trace_callback_running?: true)

      {:stopped, socket} ->
        limit = TracingHelper.trace_limit_per_period()
        period = TracingHelper.time_period() |> Parsers.parse_elapsed_time()

        socket.assigns.parent_pid
        |> push_flash(
          socket,
          "Callback tracer stopped: Too many callbacks in a short time. Current limit is #{limit} callbacks in #{period}."
        )

      {_, socket} ->
        socket
    end
    |> noreply()
  end

  @impl true
  def handle_info({:updated_trace, trace}, socket) when socket.assigns.trace_callback_running? do
    trace_display = TraceDisplay.from_trace(trace, true)

    execution_time = get_execution_times(socket)
    min_time = Keyword.get(execution_time, :exec_time_min, 0)
    max_time = Keyword.get(execution_time, :exec_time_max, :infinity)

    if trace.execution_time >= min_time and trace.execution_time <= max_time do
      socket
      |> stream_insert(:existing_traces, trace_display, at: 0, limit: @live_stream_limit)
    else
      socket
      |> stream_delete(:existing_traces, trace_display)
    end
    |> assign(trace_callback_running?: false)
    |> TracingHelper.maybe_disable_tracing_after_update()
    |> push_event("stop-timer", %{})
    |> noreply()
  end

  @impl true
  def handle_info({:updated_trace, _trace}, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:params_changed, new_params}, socket) do
    socket
    |> TracingHelper.disable_tracing()
    |> assign_node_id(new_params)
    |> assign_default_filters()
    |> reset_current_filters()
    |> assign_async_existing_traces()
    |> noreply()
  end

  @impl true
  def handle_info({:filters_updated, filters}, socket) do
    socket
    |> assign(:current_filters, filters)
    |> assign(:traces_empty?, true)
    |> assign_async_existing_traces()
    |> noreply()
  end

  @impl true
  def handle_event("refresh-history", _, socket) do
    socket
    |> assign_async_existing_traces()
    |> noreply()
  end
end
