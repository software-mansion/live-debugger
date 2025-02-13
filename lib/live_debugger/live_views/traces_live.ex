defmodule LiveDebugger.LiveViews.TracesLive do
  use LiveDebuggerWeb, :live_view

  require Logger

  import LiveDebugger.Components.Trace

  alias LiveDebugger.Services.TraceService
  alias Phoenix.PubSub

  @stream_limit 64
  @traces_number 10
  @period_ms 1000
  @interval_ms div(@period_ms, @traces_number)

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:socket_id, :string, required: true)
  attr(:node_id, :any, required: true)

  def live_render(assigns) do
    session = %{
      "socket_id" => assigns.socket_id,
      "node_id" => assigns.node_id
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__, id: @id, session: @session) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    socket_id = session["socket_id"]
    node_id = session["node_id"]

    if connected?(socket) do
      PubSub.subscribe(LiveDebugger.PubSub, "lvdbg/#{socket_id}/node_changed")
      schedule_processing()
    end

    socket
    |> assign(ets_table_id: TraceService.ets_table_id(socket_id))
    |> assign(socket_id: socket_id)
    |> assign(node_id: node_id)
    |> assign(trace_cache: %{})
    |> enable_tracing()
    |> assign_async_existing_traces()
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:debugged_node_id, :map, required: true)
  attr(:socket_id, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.collapsible_section title="Callback traces" id="traces" class="h-full md:overflow-y-auto">
        <:right_panel>
          <div class="flex gap-2 items-center">
            <.button color="primary" phx-click="switch-tracing">
              <%= if @tracing_started?, do: "Stop", else: "Start" %>
            </.button>
            <.button variant="simple" color="primary" phx-click="clear-traces">
              Clear
            </.button>
          </div>
        </:right_panel>
        <div class="w-full">
          <div id="traces-stream" phx-update="stream">
            <div id="traces-stream-empty" class="only:block hidden text-gray-700">
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
                heading="Error fetching historical traces"
              >
                The new traces still will be displayed as they come. Check logs for more
              </.alert>
            </div>
            <%= for {dom_id, trace} <- @streams.existing_traces do %>
              <.trace id={dom_id} trace={trace} />
            <% end %>
          </div>
        </div>
      </.collapsible_section>
    </div>
    """
  end

  @impl true
  def handle_event("switch-tracing", _, %{assigns: %{tracing_started?: true}} = socket) do
    socket
    |> disable_tracing()
    |> noreply()
  end

  @impl true
  def handle_event("switch-tracing", _, %{assigns: %{tracing_started?: false}} = socket) do
    socket
    |> enable_tracing()
    |> noreply()
  end

  @impl true
  def handle_event("clear-traces", _, socket) do
    ets_table_id = socket.assigns.ets_table_id
    node_id = socket.assigns.node_id

    TraceService.clear_traces(ets_table_id, node_id)

    socket
    |> stream(:existing_traces, [], reset: true)
    |> assign(trace_cache: %{})
    |> noreply()
  end

  @impl true
  def handle_async(:fetch_existing_traces, {:ok, trace_list}, socket) do
    socket
    |> assign(existing_traces_status: :ok)
    |> stream(:existing_traces, trace_list, limit: @stream_limit)
    |> noreply()
  end

  @impl true
  def handle_async(:fetch_existing_traces, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching existing traces: #{inspect(reason)}"
    )

    socket
    |> assign(existing_traces_status: :error)
    |> noreply()
  end

  @impl true
  def handle_info({:node_changed, node_id}, socket) do
    socket
    |> assign(node_id: node_id)
    |> assign_async_existing_traces()
    |> noreply()
  end

  @impl true
  def handle_info(:__do_process__, socket) do
    schedule_processing()

    traces =
      socket.assigns.trace_cache |> Map.values() |> Enum.sort_by(& &1.id, :desc)

    socket
    |> assign(trace_cache: %{})
    |> stream(:existing_traces, traces, at: 0, limit: @stream_limit)
    |> noreply()
  end

  # This is basically old limiter - it seems that it does not really impact the performance when it's here
  # So for now it can be here
  @impl true
  def handle_info({:new_trace, %{function: fun} = trace}, socket) do
    trace_cache = socket.assigns.trace_cache

    updated_trace_cache =
      trace_cache
      |> Map.get(fun)
      |> case do
        nil ->
          Map.put(trace_cache, fun, %{trace | counter: 1})

        %{counter: counter} ->
          Map.put(trace_cache, fun, %{trace | counter: counter + 1})
      end

    socket
    |> assign(trace_cache: updated_trace_cache)
    |> noreply()
  end

  defp assign_async_existing_traces(socket) do
    ets_table_id = socket.assigns.ets_table_id
    node_id = socket.assigns.node_id

    socket
    |> assign(:existing_traces_status, :loading)
    |> stream(:existing_traces, [], reset: true)
    |> start_async(:fetch_existing_traces, fn ->
      TraceService.existing_traces(ets_table_id, node_id)
    end)
  end

  defp enable_tracing(socket) do
    if(connected?(socket)) do
      socket_id = socket.assigns.socket_id
      node_id = socket.assigns.node_id

      traces_topic = "#{socket_id}/#{inspect(node_id)}/*"

      PubSub.subscribe(LiveDebugger.PubSub, "#{socket_id}/#{inspect(node_id)}/*")

      socket
      |> assign(tracing_started?: true)
      |> assign(traces_topic: traces_topic)
    else
      socket
    end
  end

  defp disable_tracing(socket) do
    if(connected?(socket)) do
      PubSub.unsubscribe(LiveDebugger.PubSub, socket.assigns.traces_topic)

      socket
      |> assign(tracing_started?: false)
      |> assign(traces_topic: nil)
    else
      socket
    end
  end

  defp schedule_processing() do
    Process.send_after(self(), :__do_process__, @interval_ms)
  end
end
