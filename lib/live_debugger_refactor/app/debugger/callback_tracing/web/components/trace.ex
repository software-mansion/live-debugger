defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.Components.Trace do
  @moduledoc """
  UI components for the traces.
  """

  use LiveDebuggerRefactor.App.Web, :component

  alias LiveDebuggerRefactor.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebuggerRefactor.App.Debugger.CallbackTracing.TraceDisplay
  alias LiveDebuggerRefactor.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebuggerRefactor.App.Utils.Parsers
  alias LiveDebuggerRefactor.App.Utils.TermParser
  alias LiveDebuggerRefactor.Structs.Trace

  attr(:id, :string, required: true)
  attr(:trace, Trace, default: nil)

  def trace_fullscreen(assigns) do
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
      <div class="w-full flex flex-col gap-4 items-start justify-center hover:[&>div>div>div>button]:hidden">
        <.trace_body id={@id <> "-fullscreen"} trace={@trace} />
      </div>
    </.fullscreen>
    """
  end

  attr(:id, :string, required: true)
  attr(:trace, Trace, required: true)

  def trace_body(assigns) do
    ~H"""
    <%= for {args, index} <- Enum.with_index(@trace.args) do %>
      <div :if={index > 0} class="border-t border-default-border w-full"></div>
      <div class="flex flex-col gap-4 w-full [&>div>div>button]:hidden hover:[&>div>div>button]:block">
        <div class="shrink-0 flex gap-2 items-center h-4">
          <p class="font-semibold">
            Arg <%= index %> (<%= Trace.arg_name(@trace, index) %>)
          </p>
          <.copy_button id={"#{@id}-arg-#{index}"} value={TermParser.term_to_copy_string(args)} />
        </div>
        <ElixirDisplay.term
          id={@id <> "-#{index}"}
          node={TermParser.term_to_display_tree(args)}
          level={1}
        />
      </div>
    <% end %>
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
          patch={RoutesHelper.debugger_node_inspector(@trace.pid, @trace.cid)}
        >
          <%= Parsers.module_to_string(@trace.module) %>
          <%= if(@trace.cid, do: "(#{@trace.cid})") %>
        </.link>
      </.tooltip>
    </div>
    """
  end

  attr(:trace, Trace, required: true)

  def callback_name(assigns) do
    assigns = assign(assigns, :content, Trace.callback_name(assigns.trace))

    ~H"""
    <p class="font-medium text-sm"><%= @content %></p>
    """
  end

  attr(:trace_display, TraceDisplay, required: true)

  def trace_time_info(assigns) do
    ~H"""
    <div class="flex text-xs font-normal text-secondary-text align-center">
      <.tooltip id={@trace_display.id <> "-timestamp-tooltip"} content="timestamp" class="min-w-24">
        <%= Parsers.parse_timestamp(@trace_display.trace.timestamp) %>
      </.tooltip>
      <span class="mx-2 border-r border-default-border"></span>
      <.tooltip
        id={@trace_display.id <> "-exec-time-tooltip"}
        content="execution time"
        class="min-w-11"
      >
        <span
          id={@trace_display.id <> "-exec-time"}
          class={["text-nowrap", get_threshold_class(@trace_display.trace.execution_time)]}
          phx-hook={if @trace_display.from_tracing?, do: "TraceExecutionTime"}
        >
          <%= Parsers.parse_elapsed_time(@trace_display.trace.execution_time) %>
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
end
