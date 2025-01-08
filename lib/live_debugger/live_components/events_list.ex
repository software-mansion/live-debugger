defmodule LiveDebugger.LiveComponents.EventsList do
  use LiveDebuggerWeb, :live_component

  require Logger

  alias LiveDebugger.Services.CallbackTracer

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{new_trace: trace}, socket) do
    debugged_node_id = socket.assigns.debugged_node_id

    cond do
      is_nil(trace.cid) and trace.pid == debugged_node_id ->
        stream_insert(socket, :existing_traces, trace, at: 0)

      not is_nil(trace.cid) and trace.cid == debugged_node_id ->
        stream_insert(socket, :existing_traces, trace, at: 0)

      true ->
        socket
    end
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(debugged_node_id: assigns.debugged_node_id)
    |> assign(id: assigns.id)
    |> assign(ets_table_id: CallbackTracer.ets_table_id(assigns.socket_id))
    |> assign_existing_traces()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      Events for {inspect(assigns.debugged_node_id)}
      <ul id={"#{assigns.id}-stream"} phx-update="stream">
        <%= for {dom_id, trace} <- @streams.existing_traces do %>
          <li id={dom_id}>{trace.module}.{trace.function}/{trace.arity} : {trace.timestamp}</li>
        <% end %>
      </ul>
    </div>
    """
  end

  @impl true
  def handle_async(:fetch_existing_traces, {:ok, trace_list}, socket) do
    socket
    |> stream(:existing_traces, trace_list)
    |> noreply()
  end

  def handle_async(:fetch_existing_traces, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching existing traces: #{inspect(reason)}"
    )

    {:noreply, socket}
  end

  defp assign_existing_traces(socket) do
    ets_table_id = socket.assigns.ets_table_id

    socket
    |> stream_configure(:existing_traces, dom_id: &"trace-#{&1.id}")
    |> stream(:existing_traces, [])
    |> start_async(:fetch_existing_traces, fn ->
      ets_table_id |> :ets.tab2list() |> Enum.map(&elem(&1, 1))
    end)
  end
end
