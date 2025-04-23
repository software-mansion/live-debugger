defmodule LiveDebugger.LiveViews.TracesLive do
  @moduledoc """
  This nested live view displays the traces of a LiveView.
  """

  use LiveDebuggerWeb, :live_view

  require Logger

  alias LiveDebugger.LiveHelpers.TracingHelper
  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Structs.TraceDisplay
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.Components.Traces

  @live_stream_limit 128
  @page_size 25
  @separator %{id: "separator"}

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true)
  attr(:node_id, :string, required: true)
  attr(:root_pid, :any, required: true)

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "node_id" => assigns.node_id,
      "id" => assigns.id,
      "parent_socket_id" => assigns.socket.id,
      "root_pid" => assigns.root_pid
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: "flex max-xl:grow xl:w-1/2"}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    lv_process = session["lv_process"]
    node_id = session["node_id"]

    if connected?(socket) do
      session["parent_socket_id"]
      |> PubSubUtils.node_changed_topic()
      |> PubSubUtils.subscribe!()
    end

    default_filters = default_filters(node_id)

    socket
    |> assign(:displayed_trace, nil)
    |> assign(:traces_continuation, nil)
    |> assign(current_filters: default_filters)
    |> assign(default_filters: default_filters)
    |> assign(traces_empty?: true)
    |> assign(node_id: node_id)
    |> assign(id: session["id"])
    |> assign(root_pid: session["root_pid"])
    |> assign(lv_process: lv_process)
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
            <.live_component
              :if={
                not @tracing_helper.tracing_started? &&
                  LiveDebugger.Feature.enabled?(:callback_filters)
              }
              module={LiveDebugger.LiveComponents.LiveDropdown}
              id="filters-dropdown"
            >
              <:button class="flex gap-2">
                <.icon name="icon-filters" class="w-4 h-4" />
                <div class="hidden @[29rem]/traces:block">Filters</div>
              </:button>
              <.live_component
                module={LiveDebugger.LiveComponents.FiltersForm}
                id="filters-form"
                node_id={@node_id}
                filters={@current_filters}
                default_filters={@default_filters}
              />
            </.live_component>
          </div>
        </:right_panel>
        <div class="w-full h-full xl:min-h-[10.25rem]">
          <div id={"#{assigns.id}-stream"} phx-update="stream" class="flex flex-col gap-2">
            <div id={"#{assigns.id}-stream-empty"} class="only:block hidden text-secondary-text">
              <div :if={@existing_traces_status == :ok}>
                No traces have been recorded yet.
              </div>
              <div
                :if={@existing_traces_status == :loading}
                class="w-full flex items-center justify-center"
              >
                <.spinner size="sm" />
              </div>
              <.alert
                :if={@existing_traces_status == :error}
                variant="danger"
                with_icon
                heading="Error fetching historical callback traces"
              >
                New events will still be displayed as they come. Check logs for more information
              </.alert>
            </div>
            <%= for {dom_id, wrapped_trace} <- @streams.existing_traces do %>
              <%= if wrapped_trace.id == "separator" do %>
                <Traces.separator id={dom_id} />
              <% else %>
                <Traces.trace id={dom_id} wrapped_trace={wrapped_trace} />
              <% end %>
            <% end %>
          </div>
          <div
            :if={LiveDebugger.Feature.enabled?(:callback_filters)}
            class="flex items-center justify-center mt-4"
          >
            <%= if @traces_continuation != :loading  do %>
              <.button
                :if={not @tracing_helper.tracing_started? && @traces_continuation != :end_of_table}
                phx-click="load-more"
                class="w-40"
                variant="secondary"
              >
                Load more
              </.button>
            <% else %>
              <.spinner size="sm" />
            <% end %>
          </div>
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
  end

  @impl true
  def handle_info({:new_trace, trace}, socket) do
    socket
    |> TracingHelper.check_fuse()
    |> case do
      {:ok, socket} ->
        trace_display = TraceDisplay.from_trace(trace)

        socket
        |> stream_insert(:existing_traces, trace_display, at: 0, limit: @live_stream_limit)
        |> assign(:traces_empty?, false)

      {:stopped, socket} ->
        limit = TracingHelper.trace_limit_per_period()
        period = TracingHelper.time_period() |> Parsers.parse_elapsed_time()

        socket.assigns.root_pid
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
  def handle_info({:node_changed, node_id}, socket) do
    default_filters = default_filters(node_id)

    socket
    |> assign(node_id: node_id)
    |> TracingHelper.disable_tracing()
    |> assign(current_filters: default_filters)
    |> assign(default_filters: default_filters)
    |> assign_async_existing_traces()
    |> noreply()
  end

  @impl true
  def handle_info({:filters_updated, filters}, socket) do
    LiveDebugger.LiveComponents.LiveDropdown.close("filters-dropdown")

    socket
    |> assign(:current_filters, filters)
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

    socket
    |> assign(:existing_traces_status, :loading)
    |> stream(:existing_traces, [], reset: true)
    |> start_async(:fetch_existing_traces, fn ->
      TraceService.existing_traces(pid,
        node_id: node_id,
        limit: @page_size,
        functions: active_functions
      )
    end)
  end

  defp load_more_existing_traces(socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id
    cont = socket.assigns.traces_continuation
    active_functions = get_active_functions(socket)

    socket
    |> assign(:traces_continuation, :loading)
    |> start_async(:load_more_existing_traces, fn ->
      TraceService.existing_traces(pid,
        node_id: node_id,
        limit: @page_size,
        cont: cont,
        functions: active_functions
      )
    end)
  end

  defp default_filters(node_id) do
    node_id
    |> TreeNode.type()
    |> case do
      :live_view -> UtilsCallbacks.live_view_callbacks()
      :live_component -> UtilsCallbacks.live_component_callbacks()
    end
    |> Enum.map(fn {function, _} -> {function, true} end)
  end

  defp get_active_functions(socket) do
    socket.assigns.current_filters
    |> Enum.filter(fn {_, active?} -> active? end)
    |> Enum.map(fn {function, _} -> function end)
  end

  defp log_async_error(operation, reason) do
    Logger.error(
      "LiveDebugger encountered unexpected error while #{operation}: #{inspect(reason)}"
    )
  end
end
