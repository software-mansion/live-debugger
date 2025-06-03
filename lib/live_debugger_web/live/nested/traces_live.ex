defmodule LiveDebuggerWeb.Live.Nested.TracesLive do
  @moduledoc """
  This nested live view displays the traces of a LiveView.
  """

  use LiveDebuggerWeb, :live_view

  require Logger

  import LiveDebuggerWeb.Helpers.NestedLiveViewHelper

  alias LiveDebuggerWeb.Helpers.TracingHelper
  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Structs.TraceDisplay
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebuggerWeb.Components.Traces

  @live_stream_limit 128
  @page_size 25
  @separator %{id: "separator"}

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
    |> assign_async_existing_traces()
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
            <Traces.toggle_tracing_button tracing_started?={@tracing_helper.tracing_started?} />
            <Traces.refresh_button :if={not @tracing_helper.tracing_started?} />
            <Traces.clear_button :if={not @tracing_helper.tracing_started?} />
            <Traces.filters_dropdown
              :if={not @tracing_helper.tracing_started?}
              node_id={@node_id}
              current_filters={@current_filters}
              default_filters={@default_filters}
            />
          </div>
        </:right_panel>
        <div class="w-full h-full">
          <Traces.traces_stream
            id={@id}
            existing_traces_status={@existing_traces_status}
            existing_traces={@streams.existing_traces}
          />
          <Traces.load_more_button
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
  def handle_async(:fetch_existing_traces, {:ok, {trace_list, cont}}, socket) do
    trace_list = Enum.map(trace_list, &TraceDisplay.from_trace/1)

    socket
    |> assign(existing_traces_status: :ok)
    |> assign(:traces_empty?, false)
    |> assign(:traces_continuation, cont)
    |> stream(:existing_traces, trace_list)
    |> noreply()
  end

  @impl true
  def handle_async(:fetch_existing_traces, {:ok, :end_of_table}, socket) do
    socket
    |> assign(existing_traces_status: :ok)
    |> assign(traces_continuation: :end_of_table)
    |> noreply()
  end

  @impl true
  def handle_async(:fetch_existing_traces, {:exit, reason}, socket) do
    log_async_error("fetching existing traces", reason)

    socket
    |> assign(existing_traces_status: :error)
    |> noreply()
  end

  @impl true
  def handle_async(:load_more_existing_traces, {:ok, {trace_list, cont}}, socket) do
    trace_list = Enum.map(trace_list, &TraceDisplay.from_trace/1)

    socket
    |> assign(:traces_continuation, cont)
    |> stream(:existing_traces, trace_list)
    |> noreply()
  end

  @impl true
  def handle_async(:load_more_existing_traces, {:ok, :end_of_table}, socket) do
    socket
    |> assign(:traces_continuation, :end_of_table)
    |> noreply()
  end

  @impl true
  def handle_async(:load_more_existing_traces, {:exit, reason}, socket) do
    log_async_error("loading more existing traces", reason)

    socket
    |> assign(:traces_continuation, :error)
    |> noreply()
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
  def handle_info({:updated_trace, _trace}, socket) do
    socket
    |> noreply()
  end

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
    LiveDebuggerWeb.LiveComponents.LiveDropdown.close("filters-dropdown")

    socket
    |> assign(:current_filters, filters)
    |> assign(:traces_empty?, true)
    |> assign_async_existing_traces()
    |> noreply()
  end

  @impl true
  def handle_event("switch-tracing", _, socket) do
    socket = TracingHelper.switch_tracing(socket)

    if socket.assigns.tracing_helper.tracing_started? and !socket.assigns.traces_empty? do
      socket
      |> stream_delete(:existing_traces, @separator)
      |> stream_insert(:existing_traces, @separator, at: 0)
    else
      socket
    end
    |> noreply()
  end

  @impl true
  def handle_event("load-more", _, socket) do
    socket
    |> load_more_existing_traces()
    |> noreply()
  end

  @impl true
  def handle_event("clear-traces", _, socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id

    TraceService.clear_traces(pid, node_id)

    socket
    |> stream(:existing_traces, [], reset: true)
    |> assign(:traces_empty?, true)
    |> noreply()
  end

  @impl true
  def handle_event("open-trace", %{"data" => string_id}, socket) do
    trace_id = String.to_integer(string_id)

    socket.assigns.lv_process.pid
    |> TraceService.get(trace_id)
    |> case do
      nil ->
        socket

      trace ->
        socket
        |> assign(displayed_trace: trace)
        |> push_event("trace-fullscreen-open", %{})
    end
    |> noreply()
  end

  @impl true
  def handle_event("toggle-collapsible", %{"trace-id" => string_trace_id}, socket) do
    trace_id = String.to_integer(string_trace_id)

    socket.assigns.lv_process.pid
    |> TraceService.get(trace_id)
    |> case do
      nil ->
        socket

      trace ->
        socket
        |> stream_insert(
          :existing_traces,
          TraceDisplay.from_trace(trace) |> TraceDisplay.render_body(),
          at: abs(trace.id)
        )
    end
    |> noreply()
  end

  @impl true
  def handle_event("refresh-history", _, socket) do
    socket
    |> assign_async_existing_traces()
    |> noreply()
  end

  defp assign_async_existing_traces(socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id
    active_functions = get_active_functions(socket)
    execution_times = get_execution_times(socket)

    socket
    |> assign(:existing_traces_status, :loading)
    |> stream(:existing_traces, [], reset: true)
    |> start_async(:fetch_existing_traces, fn ->
      TraceService.existing_traces(pid,
        node_id: node_id,
        limit: @page_size,
        functions: active_functions,
        execution_times: execution_times
      )
    end)
  end

  defp load_more_existing_traces(socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id
    cont = socket.assigns.traces_continuation
    active_functions = get_active_functions(socket)
    execution_times = get_execution_times(socket)

    socket
    |> assign(:traces_continuation, :loading)
    |> start_async(:load_more_existing_traces, fn ->
      TraceService.existing_traces(pid,
        node_id: node_id,
        limit: @page_size,
        cont: cont,
        functions: active_functions,
        execution_times: execution_times
      )
    end)
  end

  defp assign_default_filters(socket) do
    assign(socket, :default_filters, default_filters(socket.assigns.node_id))
  end

  defp reset_current_filters(socket) do
    assign(socket, :current_filters, socket.assigns.default_filters)
  end

  defp default_filters(node_id) do
    functions =
      node_id
      |> TreeNode.type()
      |> case do
        :live_view -> UtilsCallbacks.live_view_callbacks()
        :live_component -> UtilsCallbacks.live_component_callbacks()
      end
      |> Enum.map(fn {function, _} -> {function, true} end)

    %{
      functions: functions,
      execution_time: [
        {:exec_time_max, ""},
        {:exec_time_min, ""},
        {:min_unit, ""},
        {:max_unit, ""}
      ]
    }
  end

  defp get_active_functions(socket) do
    socket.assigns.current_filters.functions
    |> Enum.filter(fn {_, active?} -> active? end)
    |> Enum.map(fn {function, _} -> function end)
  end

  defp get_execution_times(socket) do
    execution_time = socket.assigns.current_filters.execution_time

    execution_time
    |> Enum.filter(fn {_, value} -> value not in ["" | Parsers.time_units()] end)
    |> Enum.map(fn {filter, value} -> {filter, String.to_integer(value)} end)
    |> Enum.map(fn {filter, value} ->
      case filter do
        :exec_time_min -> {filter, Parsers.time_to_microseconds(value, execution_time[:min_unit])}
        :exec_time_max -> {filter, Parsers.time_to_microseconds(value, execution_time[:max_unit])}
      end
    end)
  end

  defp log_async_error(operation, reason) do
    Logger.error(
      "LiveDebugger encountered unexpected error while #{operation}: #{inspect(reason)}"
    )
  end
end
