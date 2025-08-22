defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.GlobalTracesLive do
  @moduledoc """
  Nested LiveView component for displaying list of traces for all nodes in the LiveView Process.
  Sidebar is hidden by default. You can show it by sending "open-sidebar" JS event to this live view.


  ## Examples

      #{__MODULE__}.live_render(
        socket: socket,
        id: "global-traces",
        lv_process: lv_process,
        class: "flex-1"
      )

      JS.push("open-sidebar", target: "#global-traces")
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Assigns.Filters, as: FiltersAssigns
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Components.Trace,
    as: TraceComponents

  alias LiveDebugger.Structs.LvProcess

  @live_stream_limit 128
  @page_size 25

  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "id" => assigns.id,
      "lv_process" => assigns.lv_process,
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
        %{"parent_pid" => parent_pid, "lv_process" => lv_process, "id" => id},
        socket
      ) do
    socket
    |> assign(
      id: id,
      parent_pid: parent_pid,
      lv_process: lv_process,
      existing_traces_status: :loading,
      tracing_started?: false,
      traces_empty?: true,
      displayed_trace: nil,
      traces_continuation: nil,
      sidebar_hidden?: true,
      trace_search_phrase: "",
      node_id: nil
    )
    |> stream(:existing_traces, [], reset: true)
    |> put_private(:page_size, @page_size)
    |> put_private(:live_stream_limit, @live_stream_limit)
    |> FiltersAssigns.assign_current_filters()
    |> Hooks.ExistingTraces.init()
    |> Hooks.FilterNewTraces.init()
    |> Hooks.TracingFuse.init()
    |> Hooks.DisplayNewTraces.init()
    |> HookComponents.LoadMoreButton.init()
    |> HookComponents.RefreshButton.init()
    |> HookComponents.ClearButton.init()
    |> HookComponents.ToggleTracingButton.init()
    |> HookComponents.TraceWrapper.init()
    |> HookComponents.Stream.init()
    |> HookComponents.FiltersSidebar.init()
    |> HookComponents.SearchInput.init()
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
              <HookComponents.SearchInput.render
                disabled?={@tracing_started?}
                trace_search_phrase={@trace_search_phrase}
              />
            </div>
            <div class="flex gap-2 items-center h-8 px-2">
              <HookComponents.ToggleTracingButton.render tracing_started?={@tracing_started?} />
              <%= if not @tracing_started? do %>
                <HookComponents.RefreshButton.render label_class="hidden @[30rem]/traces:block" />
                <HookComponents.ClearButton.render label_class="hidden @[30rem]/traces:block" />
              <% end %>
            </div>
          </div>
          <div class="flex flex-1 overflow-auto rounded-sm bg-surface-0-bg p-4">
            <div class="w-full h-full flex flex-col gap-4">
              <HookComponents.Stream.render
                id={@id}
                existing_traces_status={@existing_traces_status}
                existing_traces={@streams.existing_traces}
              >
                <:trace :let={{id, trace_display}}>
                  <HookComponents.TraceWrapper.render id={id} trace_display={trace_display}>
                    <:label class="grid-cols-[auto_1fr_auto]">
                      <TraceComponents.module id={id} trace={trace_display.trace} class="col-span-3" />
                      <TraceComponents.callback_name trace={trace_display.trace} />
                      <TraceComponents.short_trace_content
                        id={id}
                        trace={trace_display.trace}
                        full={true}
                        phx-hook="TraceLabelSearchHighlight"
                        data-search_phrase={@trace_search_phrase}
                      />
                      <TraceComponents.trace_time_info id={id} trace_display={trace_display} />
                    </:label>

                    <:body>
                      <TraceComponents.trace_body
                        id={id}
                        trace={trace_display.trace}
                        phx-hook="TraceBodySearchHighlight"
                        data-search_phrase={@trace_search_phrase}
                      />
                    </:body>
                  </HookComponents.TraceWrapper.render>
                </:trace>
              </HookComponents.Stream.render>
              <HookComponents.LoadMoreButton.render
                :if={not @tracing_started? and not @traces_empty?}
                traces_continuation={@traces_continuation}
              />
              <TraceComponents.trace_fullscreen
                :if={@displayed_trace}
                id="trace-fullscreen"
                trace={@displayed_trace}
                phx-hook="TraceBodySearchHighlight"
                data-search_phrase={@trace_search_phrase}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    <HookComponents.FiltersSidebar.render
      sidebar_hidden?={@sidebar_hidden?}
      current_filters={@current_filters}
      tracing_started?={@tracing_started?}
    />
    """
  end
end
