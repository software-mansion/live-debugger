defmodule LiveDebuggerWeb.Live.Traces.ProcessTracesLive do
  use LiveDebuggerWeb, :live_view

  alias LiveDebuggerWeb.Live.Traces.Components
  alias LiveDebuggerWeb.Live.Traces.Helpers
  alias LiveDebuggerWeb.Live.Traces.Hooks

  @page_size 25
  @live_stream_limit 128

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true)
  attr(:params, :map, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "id" => assigns.id,
      "params" => assigns.params,
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
    socket
    |> assign(:id, session["id"])
    |> assign(:parent_pid, session["parent_pid"])
    |> assign(:lv_process, session["lv_process"])
    |> stream(:existing_traces, [], reset: true)
    |> assign(:existing_traces_status, :loading)
    |> assign(:tracing_started?, false)
    |> assign(:trace_callback_running?, false)
    |> assign(:traces_empty?, true)
    |> assign(:displayed_trace, nil)
    |> assign(:traces_continuation, nil)
    |> assign(:sidebar_hidden?, true)
    |> assign(trace_search_query: "")
    |> Helpers.assign_default_filters()
    |> Helpers.assign_current_filters()
    |> Components.LoadMoreButton.init()
    |> Hooks.FilterTraces.init()
    |> Hooks.TracingFuse.init()
    |> Hooks.ExistingTraces.init(@page_size)
    |> Hooks.NewTraces.init(@live_stream_limit)
    |> Components.RefreshButton.init()
    |> Components.ClearButton.init()
    |> Components.ToggleTracingButton.init()
    |> Components.Trace.init()
    |> Components.Stream.init()
    |> Components.FiltersSidebar.init()
    |> Components.SearchInput.init()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grow p-8 overflow-y-auto scrollbar-main">
      <div class="w-full min-w-[25rem] max-w-screen-2xl mx-auto">
        <div class="flex flex-col gap-1.5 pb-6 px-0.5">
          <.h1>Global Callback Traces</.h1>
          <span class="text-secondary-text">
            This view lists all callbacks inside debugged LiveView and its LiveComponents
          </span>
        </div>
        <div class="w-full min-w-[20rem] flex flex-col pt-2 shadow-custom rounded-sm bg-surface-0-bg border border-default-border">
          <div class="w-full flex justify-between items-center border-b border-default-border pb-2">
            <div class="ml-2">
              <Components.SearchInput.search_input />
            </div>
            <div class="flex gap-2 items-center h-8 px-2">
              <Components.ToggleTracingButton.toggle_tracing_button tracing_started?={
                @tracing_started?
              } />
              <Components.RefreshButton.refresh_button :if={not @tracing_started?} />
              <Components.ClearButton.clear_button :if={not @tracing_started?} />
            </div>
          </div>
          <div class="flex flex-1 overflow-auto rounded-sm bg-surface-0-bg p-4">
            <div class="w-full h-full flex flex-col gap-4">
              <Components.Stream.traces_stream
                id={@id}
                existing_traces_status={@existing_traces_status}
                existing_traces={@streams.existing_traces}
              >
                <:trace :let={{id, wrapped_trace}}>
                  <Components.Trace.trace id={id} wrapped_trace={wrapped_trace}>
                    <:label :let={trace_assigns} class="grid-cols-[auto_1fr_auto]">
                      <Components.Trace.module trace={trace_assigns.trace} class="col-span-3" />
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
                :if={not @tracing_started? and not @traces_empty? and @trace_search_query == ""}
                traces_continuation={@traces_continuation}
              />
              <Components.trace_fullscreen id="trace-fullscreen" trace={@displayed_trace} />
            </div>
          </div>
        </div>
      </div>
    </div>
    <Components.FiltersSidebar.sidebar
      sidebar_hidden?={@sidebar_hidden?}
      current_filters={@current_filters}
      default_filters={@default_filters}
      tracing_started?={@tracing_started?}
    />
    """
  end
end
