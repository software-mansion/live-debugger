defmodule LiveDebugger.LiveComponents.TracesList do
  @moduledoc """
  This module provides a LiveComponent to display traces.
  """

  use LiveDebuggerWeb, :live_component

  require Logger

  alias LiveDebugger.Components.ElixirDisplay
  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Utils.Parsers

  @stream_limit 32

  @impl true
  def mount(socket) do
    socket
    |> assign(:tracing_started?, true)
    |> ok()
  end

  @impl true
  def update(%{new_trace: trace}, %{assigns: %{tracing_started?: true}} = socket) do
    socket
    |> stream_insert(:existing_traces, trace, at: 0, limit: @stream_limit)
    |> ok()
  end

  @impl true
  def update(%{new_trace: _trace}, %{assigns: %{tracing_started?: false}} = socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket
    |> assign(debugged_node_id: assigns.debugged_node_id)
    |> assign(id: assigns.id)
    |> assign(ets_table_id: TraceService.ets_table_id(assigns.socket_id))
    |> assign_async_existing_traces()
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:debugged_node_id, :map, required: true)
  attr(:socket_id, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-full">
      <.collapsible_section title="Callback traces" id="traces">
        <:right_panel>
          <div class="flex gap-2 items-center">
            <.button phx-click="switch-tracing" phx-target={@myself}>
              <%= if @tracing_started?, do: "Stop", else: "Start" %>
            </.button>
            <.button variant="invert" phx-click="clear-traces" phx-target={@myself}>
              Clear
            </.button>
          </div>
        </:right_panel>
        <div class="w-full h-full lg:min-h-[10.25rem]">
          <div id={"#{assigns.id}-stream"} phx-update="stream">
            <div id={"#{assigns.id}-stream-empty"} class="only:block hidden text-gray-700">
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
  def handle_async(:fetch_existing_traces, {:ok, trace_list}, socket) do
    socket
    |> assign(existing_traces_status: :ok)
    |> stream(:existing_traces, trace_list, limit: @stream_limit)
    |> noreply()
  end

  def handle_async(:fetch_existing_traces, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching existing traces: #{inspect(reason)}"
    )

    socket
    |> assign(existing_traces_status: :error)
    |> noreply()
  end

  @impl true
  def handle_event("switch-tracing", _, socket) do
    socket
    |> assign(tracing_started?: not socket.assigns.tracing_started?)
    |> noreply()
  end

  def handle_event("clear-traces", _, socket) do
    ets_table_id = socket.assigns.ets_table_id
    node_id = socket.assigns.debugged_node_id

    TraceService.clear_traces(ets_table_id, node_id)

    socket
    |> stream(:existing_traces, [], reset: true)
    |> noreply()
  end

  attr(:id, :string, required: true)
  attr(:trace, :map, required: true, doc: "The Trace struct to render")

  defp trace(assigns) do
    assigns =
      assigns
      |> assign(:fullscreen_id, assigns.id <> "-fullscreen")
      |> assign(:callback_name, "#{assigns.trace.function}/#{assigns.trace.arity}")

    ~H"""
    <.collapsible id={@id} icon="icon-chevron-right" chevron_class="text-primary" class="max-w-full">
      <:label>
        <div class="w-full flex justify-between">
          <.tooltip
            id={"trace_" <> @id}
            position="top"
            content={"#{@trace.module}.#{@trace.function}/#{@trace.arity}"}
          >
            <div class="flex gap-4">
              <p class="text-primary font-medium"><%= @callback_name %></p>
              <p
                :if={@trace.counter > 1}
                class="text-sm text-gray-500 italic align-baseline mt-[0.2rem]"
              >
                +<%= @trace.counter - 1 %>
              </p>
            </div>
          </.tooltip>
          <p class="w-32"><%= Parsers.parse_timestamp(@trace.timestamp) %></p>
        </div>
      </:label>
      <.fullscreen id={@fullscreen_id} title={@callback_name}>
        <div class="w-full flex flex-col gap-4 items-start justify-center">
          <%= for {args, index} <- Enum.with_index(@trace.args) do %>
            <ElixirDisplay.term
              id={@id <> "-#{index}-fullscreen"}
              node={TermParser.term_to_display_tree(args)}
              level={1}
            />
          <% end %>
        </div>
      </.fullscreen>

      <div class="relative flex flex-col gap-4 overflow-x-auto max-w-full h-[30vh] max-h-max overflow-y-auto border-2 border-gray-200 p-2 rounded-lg text-gray-600">
        <.fullscreen_button id={@fullscreen_id} class="absolute right-2 top-2" />
        <%= for {args, index} <- Enum.with_index(@trace.args) do %>
          <ElixirDisplay.term
            id={@id <> "-#{index}"}
            node={TermParser.term_to_display_tree(args)}
            level={1}
          />
        <% end %>
      </div>
    </.collapsible>
    """
  end

  defp assign_async_existing_traces(socket) do
    ets_table_id = socket.assigns.ets_table_id
    node_id = socket.assigns.debugged_node_id

    socket
    |> assign(:existing_traces_status, :loading)
    |> stream(:existing_traces, [], reset: true)
    |> start_async(:fetch_existing_traces, fn ->
      TraceService.existing_traces(ets_table_id, node_id)
    end)
  end
end
