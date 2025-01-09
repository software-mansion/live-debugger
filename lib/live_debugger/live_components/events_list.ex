defmodule LiveDebugger.LiveComponents.EventsList do
  @moduledoc """
  This module provides a LiveComponent to display events.
  """

  use LiveDebuggerWeb, :live_component

  require Logger

  alias LiveDebugger.Services.CallbackTracer
  alias LiveDebugger.Components.Collapsible
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Components.Tooltip

  @impl true
  def mount(socket) do
    socket
    |> assign(:loading_error?, false)
    |> ok()
  end

  @impl true
  def update(%{new_trace: trace}, socket) do
    debugged_node_id = socket.assigns.debugged_node_id

    cond do
      is_nil(trace.cid) and trace.pid == debugged_node_id ->
        socket
        |> stream_insert(:existing_traces, trace, at: 0)
        |> assign(loading_error?: false)

      not is_nil(trace.cid) and trace.cid == debugged_node_id ->
        socket
        |> stream_insert(:existing_traces, trace, at: 0)
        |> assign(loading_error?: false)

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
    <div class="w-full">
      <.alert
        :if={@loading_error?}
        with_icon
        color="danger"
        heading="Error fetching historical events"
      >
        The new events still will be displayed as they come. Check logs for more
      </.alert>

      <div id={"#{assigns.id}-stream"} phx-update="stream">
        <%= for {dom_id, trace} <- @streams.existing_traces do %>
          <Collapsible.collapsible
            id={dom_id}
            icon="hero-chevron-down-micro"
            chevron_class="text-swm-blue"
          >
            <:label>
              <div class="w-full flex justify-between">
                <Tooltip.tooltip
                  position="top"
                  content={"#{trace.module}.#{trace.function}/#{trace.arity}"}
                >
                  <p class="text-swm-blue font-medium">{trace.function}/{trace.arity}</p>
                </Tooltip.tooltip>
                <p class="w-32">{Parsers.parse_timestamp(trace.timestamp)}</p>
              </div>
            </:label>

            <.card variant="outline">
              <.card_content class="flex flex-col gap-4">
                <%= for args <- trace.args do %>
                  <div class="whitespace-pre">{inspect(args, pretty: true, structs: false)}</div>
                <% end %>
              </.card_content>
            </.card>
          </Collapsible.collapsible>
        <% end %>
      </div>
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

    socket
    |> assign(loading_error?: true)
    |> noreply()
  end

  defp assign_existing_traces(socket) do
    ets_table_id = socket.assigns.ets_table_id

    socket
    |> stream_configure(:existing_traces, dom_id: &"trace-#{&1.id}")
    |> stream(:existing_traces, [])
    |> start_async(:fetch_existing_traces, fn ->
      CallbackTracer.get_existing_traces(ets_table_id)
    end)
  end
end
