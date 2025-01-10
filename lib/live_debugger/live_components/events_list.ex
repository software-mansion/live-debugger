defmodule LiveDebugger.LiveComponents.EventsList do
  @moduledoc """
  This module provides a LiveComponent to display events.
  """

  use LiveDebuggerWeb, :live_component

  require Logger

  alias LiveDebugger.Services.CallbackTracer
  alias LiveDebugger.Components.Trace

  @impl true
  def mount(socket) do
    socket
    |> assign(:loading_error?, false)
    |> ok()
  end

  @impl true
  def update(%{new_trace: trace}, socket) do
    socket
    |> stream_insert(:existing_traces, trace, at: 0)
    |> assign(loading_error?: false)
    |> assign(no_events?: false)
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(debugged_node_id: assigns.debugged_node_id)
    |> assign(id: assigns.id)
    |> assign(:no_events?, true)
    |> assign(ets_table_id: CallbackTracer.ets_table_id(assigns.socket_id))
    |> assign_existing_traces()
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:debugged_node_id, :map, required: true)
  attr(:socket_id, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <.alert
        :if={@loading_error?}
        with_icon
        color="danger"
        heading="Error fetching historical events"
      >
        The new events still will be displayed as they come. Check logs for more
      </.alert>
      <div :if={@no_events?} class="text-gray-500">
        No events have been recorded yet.
      </div>
      <div id={"#{@id}-stream"} phx-update="stream">
        <%= for {dom_id, trace} <- @streams.existing_traces do %>
          <Trace.trace id={dom_id} trace={trace} />
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  @spec handle_async(:fetch_existing_traces, {:exit, any()} | {:ok, any()}, any()) ::
          {:noreply, any()}
  def handle_async(:fetch_existing_traces, {:ok, trace_list}, socket) do
    socket
    |> stream(:existing_traces, trace_list)
    |> assign(:no_events?, Enum.empty?(trace_list))
    |> noreply()
  end

  def handle_async(:fetch_existing_traces, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching existing traces: #{inspect(reason)}"
    )

    socket
    |> assign(loading_error?: true)
    |> noreply()
  end

  defp assign_existing_traces(socket) do
    ets_table_id = socket.assigns.ets_table_id
    node_id = socket.assigns.debugged_node_id

    socket
    |> stream(:existing_traces, [], reset: true)
    |> start_async(:fetch_existing_traces, fn ->
      CallbackTracer.get_existing_traces(ets_table_id, node_id)
    end)
  end
end
