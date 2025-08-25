defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.NodeTracesLive do
  @moduledoc """
  Nested LiveView component for displaying list of traces for specific node.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Assigns.Filters, as: FiltersAssigns
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Components.Trace,
    as: TraceComponents

  alias LiveDebugger.Structs.LvProcess

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged

  @live_stream_limit 128
  @page_size 25

  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:node_id, :any, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "node_id" => assigns.node_id,
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
  def mount(
        _params,
        %{
          "parent_pid" => parent_pid,
          "lv_process" => lv_process,
          "id" => id,
          "node_id" => node_id
        },
        socket
      ) do
    if connected?(socket) do
      Bus.receive_events!(parent_pid)
    end

    socket
    |> assign(
      id: id,
      parent_pid: parent_pid,
      lv_process: lv_process,
      node_id: node_id,
      traces_empty?: true,
      traces_continuation: nil,
      existing_traces_status: :loading,
      displayed_trace: nil,
      tracing_started?: false,
      trace_callback_running?: false
    )
    |> stream(:existing_traces, [], reset: true)
    |> put_private(:page_size, @page_size)
    |> put_private(:live_stream_limit, @live_stream_limit)
    |> FiltersAssigns.assign_current_filters()
    |> Hooks.ExistingTraces.init()
    |> Hooks.FilterNewTraces.init()
    |> Hooks.TracingFuse.init()
    |> Hooks.DisplayNewTraces.init()
    |> HookComponents.ClearButton.init()
    |> HookComponents.LoadMoreButton.init()
    |> HookComponents.TraceWrapper.init()
    |> HookComponents.Stream.init()
    |> HookComponents.FiltersFullscreen.init()
    |> HookComponents.RefreshButton.init()
    |> HookComponents.ToggleTracingButton.init()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-full @container/traces flex flex-1">
      <.section title="Callback traces" id="traces" inner_class="mx-0 my-4 px-4" class="flex-1">
        <:right_panel>
          <div class="flex gap-2 items-center">
            <HookComponents.ToggleTracingButton.render tracing_started?={@tracing_started?} />
            <%= if not @tracing_started? do %>
              <HookComponents.RefreshButton.render label_class="hidden @[30rem]/traces:block" />
              <HookComponents.ClearButton.render label_class="hidden @[30rem]/traces:block" />
              <HookComponents.FiltersFullscreen.filters_button
                label_class="hidden @[30rem]/traces:block"
                current_filters={@current_filters}
              />
            <% end %>
          </div>
        </:right_panel>
        <div class="w-full h-full flex flex-col gap-4">
          <HookComponents.Stream.render
            id={@id}
            existing_traces_status={@existing_traces_status}
            existing_traces={@streams.existing_traces}
          >
            <:trace :let={{id, trace_display}}>
              <HookComponents.TraceWrapper.render id={id} trace_display={trace_display}>
                <:label class="grid-cols-[auto_1fr_auto]">
                  <TraceComponents.callback_name trace={trace_display.trace} />
                  <TraceComponents.short_trace_content trace={trace_display.trace} />
                  <TraceComponents.trace_time_info id={id} trace_display={trace_display} />
                </:label>

                <:body>
                  <TraceComponents.trace_body id={id} trace={trace_display.trace} />
                </:body>
              </HookComponents.TraceWrapper.render>
            </:trace>
          </HookComponents.Stream.render>
          <HookComponents.LoadMoreButton.render
            :if={not @tracing_started? and not @traces_empty?}
            traces_continuation={@traces_continuation}
          />
        </div>
      </.section>

      <HookComponents.FiltersFullscreen.render node_id={@node_id} current_filters={@current_filters} />
      <TraceComponents.trace_fullscreen
        :if={@displayed_trace}
        id="trace-fullscreen"
        trace={@displayed_trace}
      />
    </div>
    """
  end

  @impl true
  def handle_info(
        %NodeIdParamChanged{node_id: node_id, debugger_pid: pid},
        %{assigns: %{parent_pid: pid}} = socket
      ) do
    socket
    |> assign(:node_id, node_id)
    |> FiltersAssigns.assign_current_filters()
    |> Hooks.TracingFuse.disable_tracing()
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
