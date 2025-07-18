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
  alias LiveDebugger.Utils.Parsers
  alias LiveDebuggerWeb.Hooks.Flash
  alias LiveDebuggerWeb.Live.Traces.Components
  alias LiveDebuggerWeb.Helpers.RoutesHelper

  @required_assigns [:lv_process, :displayed_trace]

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

  slot :label, required: true do
    attr(:class, :string, doc: "Additional class for label")
  end

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
      label_class={[
        "font-semibold bg-surface-1-bg p-2 py-3",
        @trace.type == :exception_from && "border border-error-icon"
      ]}
      phx-click={if(@render_body?, do: nil, else: "toggle-collapsible")}
      phx-value-trace-id={@trace.id}
    >
      <:label>
        <div
          :for={label <- @label}
          id={@id <> "-label"}
          class={["w-[90%] grow grid items-center gap-x-3 ml-2" | List.wrap(label[:class])]}
        >
          <%= render_slot(@label, assigns) %>
        </div>
      </:label>
      <div class="relative">
        <div :if={@render_body?} class="absolute right-0 top-0 z-10">
          <.fullscreen_button
            id={"trace-fullscreen-#{@id}"}
            class="m-2"
            phx-click="open-trace"
            phx-value-data={@trace.id}
          />
        </div>
        <div class="flex flex-col gap-4 overflow-x-auto max-w-full max-h-[30vh] overflow-y-auto p-4">
          <%= if @render_body? do %>
            <Components.trace_body id={@id} trace_args={@trace.args} trace={@trace} />
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

  attr(:trace, Trace, required: true)
  attr(:class, :string, default: "")

  def module(assigns) do
    ~H"""
    <div class={["text-primary text-2xs font-normal truncate", @class]}>
      <.tooltip id={"#{@trace.id}-trace-module"} content="See in Node Inspector" class="w-max">
        <.link
          class="block hover:underline"
          patch={RoutesHelper.channel_dashboard(@trace.pid, @trace.cid)}
        >
          <%= Parsers.module_to_string(@trace.module) %>
          <%= if(@trace.cid, do: "(#{@trace.cid})") %>
        </.link>
      </.tooltip>
    </div>
    """
  end

  attr(:content, :string, required: true)

  def callback_name(assigns) do
    ~H"""
    <p class="font-medium text-sm"><%= @content %></p>
    """
  end

  attr(:trace, :map, default: nil)

  def short_trace_content(assigns) do
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

  def trace_time_info(assigns) do
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
