defmodule LiveDebuggerWeb.Live.Traces.Components.Trace do
  @moduledoc """
  This component is responsible for rendering a single trace.

  It produces `open-trace` event when clicked that can be handled by hook declared via `init/1`.
  It also produces `toggle-collapsible` event when clicked that can be handled by hook declared via `init/1`.
  """

  use LiveDebuggerWeb, :hook_component

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Structs.TraceDisplay
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Utils.Parsers
  alias LiveDebuggerWeb.Components.ElixirDisplay
  alias LiveDebuggerWeb.Hooks.Flash

  @required_assigns [:id, :lv_process, :displayed_trace]

  @doc """
  Initializes the trace component by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:trace, :handle_event, &handle_event/3)
    |> register_hook(:trace)
  end

  @doc """
  Renders the trace component.
  It produces `open-trace` event when clicked that can be handled by hook declared via `init/1`.
  It also produces `toggle-collapsible` event when clicked that can be handled by hook declared via `init/1`.
  """

  attr(:id, :string, required: true)
  attr(:wrapped_trace, :map, required: true, doc: "The Trace to render")

  def trace(assigns) do
    assigns =
      assigns
      |> assign(:trace, assigns.wrapped_trace.trace)
      |> assign(:render_body?, assigns.wrapped_trace.render_body?)
      |> assign(:from_tracing?, assigns.wrapped_trace.from_tracing?)
      |> assign(:callback_name, Trace.callback_name(assigns.wrapped_trace.trace))

    ~H"""
    <.collapsible
      id={@id}
      icon="icon-chevron-right"
      chevron_class="w-5 h-5 text-accent-icon"
      class="max-w-full border border-default-border rounded last:mb-4"
      label_class="font-semibold bg-surface-1-bg h-10 p-2"
      phx-click={if(@render_body?, do: nil, else: "toggle-collapsible")}
      phx-value-trace-id={@trace.id}
    >
      <:label>
        <div id={@id <> "-label"} class="w-[90%] grow flex items-center ml-2 gap-3">
          <p class="font-medium text-sm"><%= @callback_name %></p>
          <.short_trace_content trace={@trace} />
          <.trace_time_info id={@id} trace={@trace} from_tracing?={@from_tracing?} />
        </div>
      </:label>
      <div class="relative">
        <div class="absolute right-0 top-0 z-10">
          <.fullscreen_button
            id={"trace-fullscreen-#{@id}"}
            class="m-2"
            phx-click="open-trace"
            phx-value-data={@trace.id}
          />
        </div>
        <div class="flex flex-col gap-4 overflow-x-auto max-w-full max-h-[30vh] overflow-y-auto p-4">
          <%= if @render_body? do %>
            <%= for {args, index} <- Enum.with_index(@trace.args) do %>
              <div :if={index > 0} class="border-t border-default-border"></div>
              <p class="font-semibold">Arg <%= index %> (<%= Trace.arg_name(@trace, index) %>)</p>
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
      </div>
    </.collapsible>
    """
  end

  attr(:trace, :map, default: nil)

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
  attr(:from_tracing?, :boolean, default: false)

  defp trace_time_info(assigns) do
    ~H"""
    <div class="flex text-xs font-normal text-secondary-text align-center">
      <.tooltip id={@id <> "-timestamp"} content="timestamp" class="min-w-24">
        <%= Parsers.parse_timestamp(@trace.timestamp) %>
      </.tooltip>
      <span class="mx-2 border-r border-default-border"></span>
      <.tooltip id={@id <> "-exec-time-tooltip"} content="execution time" class="min-w-11">
        <span
          id={@id <> "-exec-time"}
          class={["text-nowrap", get_threshold_class(@trace.execution_time)]}
          phx-hook={if @from_tracing?, do: "TraceExecutionTime"}
        >
          <%= Parsers.parse_elapsed_time(@trace.execution_time) %>
        </span>
      </.tooltip>
    </div>
    """
  end

  defp get_threshold_class(execution_time) do
    cond do
      execution_time == nil -> ""
      execution_time > 500_000 -> "text-error-text"
      execution_time > 100_000 -> "text-warning-text"
      true -> ""
    end
  end

  defp handle_event("open-trace", %{"data" => string_id}, socket) do
    trace_id = String.to_integer(string_id)

    socket.assigns.lv_process.pid
    |> TraceService.get(trace_id)
    |> case do
      nil ->
        socket

      trace ->
        socket
        |> assign(displayed_trace: trace)
        |> push_event("trace-fullscreen-open", %{})
    end
    |> halt()
  end

  defp handle_event("toggle-collapsible", %{"trace-id" => string_trace_id}, socket) do
    trace_id = String.to_integer(string_trace_id)

    socket.assigns.lv_process.pid
    |> TraceService.get(trace_id)
    |> case do
      nil ->
        socket
        |> Flash.push_flash("Trace has been removed.", socket.assigns.root_pid)
        |> push_event("#{:existing_traces}-#{string_trace_id}-collapsible", %{action: "close"})

      trace ->
        socket
        |> stream_insert(
          :existing_traces,
          TraceDisplay.from_trace(trace) |> TraceDisplay.render_body(),
          at: abs(trace.id)
        )
    end
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
