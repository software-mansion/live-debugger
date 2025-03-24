defmodule LiveDebugger.LiveComponents.TracesList do
  @moduledoc """
  This module provides a LiveComponent to display traces.
  """

  use LiveDebuggerWeb, :live_component

  require Logger

  alias LiveDebugger.LiveHelpers.TracingHelper
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Components.ElixirDisplay
  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Structs.TraceDisplay

  @stream_limit 128
  @separator %{id: "separator"}

  @impl true
  def mount(socket) do
    socket
    |> assign(:displayed_trace, nil)
    |> ok()
  end

  @impl true
  def update(%{new_trace: trace}, socket) do
    socket
    |> TracingHelper.check_fuse()
    |> case do
      {:ok, socket} ->
        trace_display = TraceDisplay.from_trace(trace)

        socket
        |> stream_insert(:existing_traces, trace_display, at: 0, limit: @stream_limit)
        |> assign(:traces_empty?, false)

      {_, socket} ->
        # Add disappearing flash here in case of :stopped. (Issue 173)
        socket
    end
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> TracingHelper.init()
    |> assign(:traces_empty?, true)
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
      <.section title="Callback traces" id="traces" inner_class="p-4">
        <:right_panel>
          <div class="flex gap-2 items-center">
            <.toggle_tracing_button
              myself={@myself}
              tracing_started?={@tracing_helper.tracing_started?}
            />
            <.button
              :if={not @tracing_helper.tracing_started?}
              phx-click="refresh-history"
              phx-target={@myself}
              class="flex gap-2"
              variant="secondary"
              size="sm"
            >
              Refresh
            </.button>
            <.button
              :if={not @tracing_helper.tracing_started?}
              variant="secondary"
              size="sm"
              phx-click="clear-traces"
              phx-target={@myself}
            >
              Clear
            </.button>
          </div>
        </:right_panel>
        <div class="w-full h-full lg:min-h-[10.25rem]">
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
                <.separator id={dom_id} />
              <% else %>
                <.trace id={dom_id} wrapped_trace={wrapped_trace} myself={@myself} />
              <% end %>
            <% end %>
          </div>
        </div>
      </.section>
      <.trace_fullscreen id="trace-fullscreen" trace={@displayed_trace} />
    </div>
    """
  end

  @impl true
  def handle_async(:fetch_existing_traces, {:ok, []}, socket) do
    socket
    |> assign(existing_traces_status: :ok)
    |> noreply()
  end

  def handle_async(:fetch_existing_traces, {:ok, trace_list}, socket) do
    trace_list = Enum.map(trace_list, &TraceDisplay.from_trace/1)

    socket
    |> assign(existing_traces_status: :ok)
    |> assign(:traces_empty?, false)
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
    socket = TracingHelper.switch_tracing(socket)

    if socket.assigns.tracing_helper.tracing_started? and !socket.assigns.traces_empty? do
      socket
      |> stream_delete(:existing_traces, @separator)
      |> stream_insert(:existing_traces, @separator, at: 0, limit: @stream_limit)
    else
      socket
    end
    |> noreply()
  end

  @impl true
  def handle_event("clear-traces", _, socket) do
    ets_table_id = socket.assigns.ets_table_id
    node_id = socket.assigns.debugged_node_id

    TraceService.clear_traces(ets_table_id, node_id)

    socket
    |> stream(:existing_traces, [], reset: true)
    |> assign(:traces_empty?, true)
    |> noreply()
  end

  @impl true
  def handle_event("open-trace", %{"data" => string_id}, socket) do
    trace_id = String.to_integer(string_id)

    socket.assigns.ets_table_id
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

    socket.assigns.ets_table_id
    |> TraceService.get(trace_id)
    |> case do
      nil ->
        socket

      trace ->
        socket
        |> stream_insert(
          :existing_traces,
          TraceDisplay.from_trace(trace) |> TraceDisplay.render_body(),
          at: abs(trace.id),
          limit: @stream_limit
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

  defp separator(assigns) do
    ~H"""
    <div id={@id}>
      <div class="h-6 my-1 font-normal text-xs text-secondary-text flex align items-center">
        <div class="border-b border-default-border grow"></div>
        <span class="mx-2">Past Traces</span>
        <div class="border-b border-default-border grow"></div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:wrapped_trace, :map, required: true, doc: "The Trace to render")
  attr(:myself, :any, required: true)

  defp trace(assigns) do
    assigns =
      assigns
      |> assign(:trace, assigns.wrapped_trace.trace)
      |> assign(:render_body?, assigns.wrapped_trace.render_body?)
      |> assign(:callback_name, Trace.callback_name(assigns.wrapped_trace.trace))

    ~H"""
    <.collapsible
      id={@id}
      icon="icon-chevron-right"
      chevron_class="w-5 h-5 text-accent-icon"
      class="max-w-full border border-default-border rounded"
      label_class="font-semibold bg-surface-1-bg h-10 p-2"
      phx-click={if(@render_body?, do: nil, else: "toggle-collapsible")}
      phx-target={@myself}
      phx-value-trace-id={@trace.id}
    >
      <:label>
        <div
          id={@id <> "-label"}
          class="w-[90%] grow flex items-center ml-2 gap-1.5"
          phx-update="ignore"
        >
          <p class="font-medium text-sm"><%= @callback_name %></p>
          <.short_trace_content trace={@trace} />
          <p class="w-max text-xs font-normal text-secondary-text align-center">
            <%= Parsers.parse_timestamp(@trace.timestamp) %>
          </p>
        </div>
      </:label>
      <div class="relative flex flex-col gap-4 overflow-x-auto max-w-full h-[30vh] max-h-max overflow-y-auto p-4">
        <.fullscreen_button
          id={"trace-fullscreen-#{@id}"}
          class="absolute right-2 top-2"
          on_click="open-trace"
          on_click_target={@myself}
          on_click_data={@trace.id}
        />

        <%= if @render_body? do %>
          <%= for {args, index} <- Enum.with_index(@trace.args) do %>
            <ElixirDisplay.term
              id={@id <> "-#{index}"}
              node={TermParser.term_to_display_tree(args)}
              level={1}
            />
          <% end %>
        <% else %>
          <div class="w-full flex items-center justify-center">
            <.spinner size="sm" />
          </div>
        <% end %>
      </div>
    </.collapsible>
    """
  end

  defp short_trace_content(assigns) do
    assigns = assign(assigns, :content, Enum.map_join(assigns.trace.args, " ", &inspect/1))

    ~H"""
    <div class="grow shrink text-secondary-text font-code font-normal text-3xs truncate">
      <p class="hide-on-open mt-0.5"><%= @content %></p>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:trace, :map, default: nil)

  defp trace_fullscreen(assigns) do
    assigns =
      case assigns.trace do
        nil ->
          assigns
          |> assign(:callback_name, "Unknown trace")
          |> assign(:trace_args, [])

        trace ->
          assigns
          |> assign(:callback_name, Trace.callback_name(trace))
          |> assign(:trace_args, trace.args)
      end

    ~H"""
    <.fullscreen id={@id} title={@callback_name}>
      <div class="w-full flex flex-col gap-4 items-start justify-center">
        <%= for {args, index} <- Enum.with_index(@trace_args) do %>
          <ElixirDisplay.term
            id={@id <> "-#{index}-fullscreen"}
            node={TermParser.term_to_display_tree(args)}
            level={1}
          />
        <% end %>
      </div>
    </.fullscreen>
    """
  end

  defp assign_async_existing_traces(socket) do
    ets_table_id = socket.assigns.ets_table_id
    node_id = socket.assigns.debugged_node_id

    socket
    |> assign(:existing_traces_status, :loading)
    |> stream(:existing_traces, [], reset: true)
    |> start_async(:fetch_existing_traces, fn ->
      TraceService.existing_traces(ets_table_id, node_id, @stream_limit)
    end)
  end
end
