defmodule LiveDebugger.LiveComponents.EventsList do
  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Services.CallbackTracer

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{new_trace: trace}, socket) do
    socket
    |> assign(existing_traces: [trace | socket.assigns.existing_traces])
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(debugged_node_id: assigns.debugged_node_id)
    |> assign(ets_table_id: CallbackTracer.ets_table_id(assigns.socket_id))
    |> assign_existing_traces()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      Events for {inspect(assigns.debugged_node_id)}
      <ul>
        <%= for trace <- assigns.existing_traces do %>
          <li>{trace.module}.{trace.function}/{trace.arity}</li>
        <% end %>
      </ul>
    </div>
    """
  end

  defp assign_existing_traces(socket) do
    existing_traces = socket.assigns.ets_table_id |> :ets.tab2list() |> Enum.map(&elem(&1, 1))

    assign(socket, existing_traces: existing_traces)
  end
end
