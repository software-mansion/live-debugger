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

  @stream_limit 128

  @impl true
  def mount(socket) do
    socket
    |> assign(:tracing_started?, false)
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
      <.collapsible_section title="Callback traces" id="traces" inner_class="p-4">
        <:right_panel>
          <div class="flex gap-2 items-center">
            <.toggle_tracing_button myself={@myself} tracing_started?={@tracing_started?} />
            <.button variant="secondary" size="sm" phx-click="clear-traces" phx-target={@myself}>
              Clear
            </.button>
          </div>
        </:right_panel>
        <div class="w-full h-full lg:min-h-[10.25rem]">
          <div id={"#{assigns.id}-stream"} phx-update="stream" class="flex flex-col gap-2">
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
                heading="Error fetching historical callback traces"
              >
                New events will still be displayed as they come. Check logs for more information
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

  attr(:tracing_started?, :boolean, required: true)
  attr(:myself, :any, required: true)

  defp toggle_tracing_button(assigns) do
    ~H"""
    <.button phx-click="switch-tracing" phx-target={@myself} class="flex gap-2" size="sm">
      <div class="flex gap-1.5 items-center w-12">
        <%= if @tracing_started? do %>
          <.icon name="icon-stop" class="w-4 h-4" />
          <div>Stop</div>
        <% else %>
          <.icon name="icon-play" class="w-3.5 h-3.5" />
          <div>Start</div>
        <% end %>
      </div>
    </.button>
    """
  end

  attr(:id, :string, required: true)
  attr(:trace, :map, required: true, doc: "The Trace struct to render")

  defp trace(assigns) do
    assigns =
      assigns
      |> assign(:fullscreen_id, assigns.id <> "-fullscreen")
      |> assign(:callback_name, "#{assigns.trace.function}/#{assigns.trace.arity}")

    ~H"""
    <.collapsible
      id={@id}
      icon="icon-chevron-right"
      chevron_class="w-5 h-5 text-primary-900"
      class="max-w-full border border-secondary-200 rounded"
      label_class="font-semibold bg-secondary-50 h-10 p-2"
    >
      <:label>
        <div class="w-[90%] grow flex items-center ml-2 gap-1.5">
          <div class="flex gap-1.5 items-center">
            <p class="font-medium text-sm"><%= @callback_name %></p>
            <.aggregate_count :if={@trace.counter > 1} count={@trace.counter} />
          </div>
          <.short_trace_content trace={@trace} />
          <p class="w-max text-xs font-normal text-secondary-600 align-center">
            <%= Parsers.parse_timestamp(@trace.timestamp) %>
          </p>
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

      <div class="relative flex flex-col gap-4 overflow-x-auto max-w-full h-[30vh] max-h-max overflow-y-auto p-4">
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

  defp aggregate_count(assigns) do
    ~H"""
    <span class="rounded-full bg-white border border-secondary-200  text-2xs px-1.5">
      +<%= assigns.count %>
    </span>
    """
  end

  defp short_trace_content(assigns) do
    assigns = assign(assigns, :content, Enum.map_join(assigns.trace.args, " ", &inspect/1))

    ~H"""
    <div class="grow shrink text-secondary-600 font-code font-normal text-3xs truncate">
      <p class="hide-on-open mt-0.5"><%= @content %></p>
    </div>
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
