defmodule LiveDebuggerWeb.Live.Traces.NodeTracesLive do
  @moduledoc """
  This nested live view displays the traces of a LiveView.
  """

  use LiveDebuggerWeb, :live_view

  alias LiveDebuggerWeb.Helpers.NestedLiveViewHelper

  alias LiveDebuggerWeb.Live.Traces.Hooks
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebuggerWeb.Live.Traces.Components
  alias LiveDebuggerWeb.Live.Traces.Helpers

  @live_stream_limit 128
  @page_size 25

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true)
  attr(:params, :map, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "params" => assigns.params,
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
  def mount(_params, session, socket) do
    parent_pid = session["parent_pid"]

    if connected?(socket) do
      parent_pid
      |> PubSubUtils.params_changed_topic()
      |> PubSubUtils.subscribe!()
    end

    socket
    |> assign(:id, session["id"])
    |> assign(:parent_pid, session["parent_pid"])
    |> assign(:lv_process, session["lv_process"])
    |> stream(:existing_traces, [], reset: true)
    |> assign(:traces_empty?, true)
    |> assign(:traces_continuation, nil)
    |> assign(:existing_traces_status, :loading)
    |> assign(:displayed_trace, nil)
    |> assign(:trace_callback_running?, false)
    |> assign(:tracing_started?, false)
    |> NestedLiveViewHelper.assign_node_id(session)
    |> Helpers.assign_default_filters()
    |> Helpers.assign_current_filters()
    |> Components.ClearButton.init()
    |> Components.LoadMoreButton.init(@page_size)
    |> Components.Trace.init()
    |> Components.Stream.init()
    |> Hooks.TracingFuse.init()
    |> Hooks.ExistingTraces.init(@page_size)
    |> Hooks.NewTraces.init(@live_stream_limit)
    |> Components.FiltersFullscreen.init()
    |> Components.RefreshButton.init()
    |> Components.ToggleTracingButton.init()
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
            <Components.ToggleTracingButton.toggle_tracing_button tracing_started?={@tracing_started?} />
            <Components.RefreshButton.refresh_button
              :if={not @tracing_started?}
              label_class="hidden @[30rem]/traces:block"
            />
            <Components.ClearButton.clear_button
              :if={not @tracing_started?}
              label_class="hidden @[30rem]/traces:block"
            />
            <Components.FiltersFullscreen.filters_button
              :if={not @tracing_started?}
              label_class="hidden @[30rem]/traces:block"
              current_filters={@current_filters}
              default_filters={@default_filters}
            />
          </div>
        </:right_panel>
        <div class="w-full h-full flex flex-col gap-4">
          <Components.Stream.traces_stream
            id={@id}
            existing_traces_status={@existing_traces_status}
            existing_traces={@streams.existing_traces}
          >
            <:trace :let={{id, wrapped_trace}}>
              <Components.Trace.trace id={id} wrapped_trace={wrapped_trace}>
                <:label :let={trace_assigns} class="grid-cols-[auto_1fr_auto]">
                  <Components.Trace.callback_name content={trace_assigns.callback_name} />
                  <Components.Trace.short_trace_content trace={trace_assigns.trace} />
                  <Components.Trace.trace_time_info
                    id={trace_assigns.id}
                    trace={trace_assigns.trace}
                    from_tracing?={trace_assigns.from_tracing?}
                  />
                </:label>
              </Components.Trace.trace>
            </:trace>
          </Components.Stream.traces_stream>
          <Components.LoadMoreButton.load_more_button
            :if={not @tracing_started? and not @traces_empty?}
            traces_continuation={@traces_continuation}
          />
        </div>
      </.section>

      <Components.FiltersFullscreen.filters_fullscreen
        node_id={@node_id}
        current_filters={@current_filters}
        default_filters={@default_filters}
      />
      <Components.trace_fullscreen id="trace-fullscreen" trace={@displayed_trace} />
    </div>
    """
  end

  @impl true
  def handle_info({:params_changed, new_params}, socket) do
    socket
    |> Hooks.TracingFuse.disable_tracing()
    |> NestedLiveViewHelper.assign_node_id(new_params)
    |> Helpers.assign_default_filters()
    |> Helpers.reset_current_filters()
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> noreply()
  end
end
