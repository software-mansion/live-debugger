defmodule LiveDebugger.App.Debugger.LiveViewDiffs.Web.LvDiffLive do
  @moduledoc """
  This LiveView displays a list of LiveView diffs.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Debugger.LiveViewDiffs.Web.HookComponents

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
    |> assign(id: id)
    |> assign(lv_process: lv_process)
    |> assign(parent_pid: parent_pid)
    |> assign(existing_diffs_status: :ok)
    |> stream(:existing_diffs, [], reset: true)
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grow p-8 overflow-y-auto scrollbar-main">
      <div class="w-full min-w-[25rem] max-w-screen-2xl mx-auto">
        <div class="flex flex-col gap-1.5 pb-6 px-0.5">
          <.h1>LiveView Diffs</.h1>
          <span class="text-secondary-text">
            This view lists all diffs that this LiveView sent to the browser.
          </span>
        </div>
        <div class="@container/traces w-full min-w-[20rem] flex flex-col pt-2 shadow-custom rounded-sm bg-surface-0-bg border border-default-border">
          <div class="w-full flex justify-between items-center border-b border-default-border pb-2">
            <div class="flex gap-2 items-center h-8 px-2">
              <%!-- <HookComponents.ToggleTracingButton.render tracing_started?={@tracing_started?} />
              <%= if not @tracing_started? do %>
                <HookComponents.RefreshButton.render label_class="hidden @[30rem]/traces:block" />
                <HookComponents.ClearButton.render label_class="hidden @[30rem]/traces:block" />
              <% end %> --%>
              <p>Buttons will be here</p>
            </div>
          </div>
          <div class="flex flex-1 overflow-auto rounded-sm bg-surface-0-bg p-4">
            <div class="w-full h-full flex flex-col gap-4">
              <HookComponents.Stream.render
                id={@id}
                existing_diffs_status={@existing_diffs_status}
                existing_diffs={@streams.existing_diffs}
              >
                <:diff :let={{id, wrapped_diff}}>
                  <p>{id}</p>
                  <% dbg(wrapped_diff) %>
                </:diff>
              </HookComponents.Stream.render>
              <%!-- <HookComponents.LoadMoreButton.render
                :if={not @tracing_started? and not @traces_empty?}
                traces_continuation={@traces_continuation}
              /> --%>
              <%!-- <TraceComponents.trace_fullscreen
                :if={@displayed_trace}
                id="trace-fullscreen"
                trace={@displayed_trace}
                phx-hook="TraceBodySearchHighlight"
                data-search_phrase={@trace_search_phrase}
              /> --%>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
