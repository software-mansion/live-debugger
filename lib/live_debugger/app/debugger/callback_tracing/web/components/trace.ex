defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.Components.Trace do
  @moduledoc """
  UI components for the traces.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplay
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.Utils.Memory

  @doc """
  Fullscreen modal with trace body.
  """
  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)
  attr(:rest, :global)

  def trace_fullscreen(assigns) do
    ~H"""
    <.fullscreen id={@id} title={@trace_display.title}>
      <div class="p-4 flex flex-col gap-4 items-start justify-center hover:[&>div>div>div>button]:hidden">
        <.trace_body id={@id <> "-fullscreen"} trace_display={@trace_display} {@rest} />
      </div>
    </.fullscreen>
    """
  end

  @doc """
  List of trace's args.
  """
  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)
  attr(:rest, :global)

  def trace_body(assigns) do
    ~H"""
    <div id={@id <> "-body"} class="flex flex-col gap-4 w-full" {@rest}>
      <%= for {{label, content}, index} <- Enum.with_index(@trace_display.body) do %>
        <div :if={index > 0} class="border-t border-default-border w-full"></div>
        <div class="flex flex-col gap-4 w-full [&>div>div>button]:hidden hover:[&>div>div>button]:block">
          <div class="shrink-0 flex gap-2 items-center h-4">
            <p class="font-semibold">
              <%= label %>
            </p>
            <.copy_button id={"#{@id}-arg-#{index}"} value={TermParser.term_to_copy_string(content)} />
          </div>
          <ElixirDisplay.term id={@id <> "-#{index}"} node={TermParser.term_to_display_tree(content)} />
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Module of the trace.
  """
  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)
  attr(:class, :string, default: "")

  def trace_module(assigns) do
    ~H"""
    <div class={["text-primary text-2xs font-normal truncate", @class]}>
      <.tooltip id={"#{@id}-trace-module"} content="See in Node Inspector" class="w-max">
        <.link
          class="block hover:underline"
          patch={RoutesHelper.debugger_node_inspector(@trace_display.pid, @trace_display.cid)}
        >
          <%= @trace_display.module %>
          <%= if(@trace_display.cid, do: "(#{@trace_display.cid})") %>
        </.link>
      </.tooltip>
    </div>
    """
  end

  @doc """
  Callback name of the trace.
  """
  attr(:trace_display, TraceDisplay, required: true)

  def trace_title(assigns) do
    ~H"""
    <p class="font-medium text-sm">
      <%= @trace_display.title %>
    </p>
    """
  end

  attr(:id, :string, default: nil)
  attr(:trace_display, TraceDisplay, required: true)
  attr(:full, :boolean, default: false)
  attr(:rest, :global)

  def trace_short_content(assigns) do
    ~H"""
    <div class="grow shrink text-secondary-text font-code font-normal text-3xs truncate">
      <div class="hidden @[30rem]/traces:flex">
        <p id={if(@id, do: @id <> "-short-content", else: false)} class="hide-on-open mt-0.5" {@rest}>
          <%= TraceDisplay.short_content(@trace_display, @full) %>
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Timestamp and execution time of the trace.
  """

  slot(:left_section, required: true)
  slot(:right_section, required: true)

  def trace_side_section(assigns) do
    ~H"""
    <div class="flex text-xs font-normal text-secondary-text align-center">
      <%= render_slot(@left_section) %>
      <span class="mx-2 border-r border-default-border"></span>
      <%= render_slot(@right_section) %>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:timestamp, :integer, required: true)

  def trace_timestamp_info(assigns) do
    ~H"""
    <.tooltip id={@id <> "-timestamp-tooltip"} content="timestamp" class="min-w-24">
      <%= Parsers.parse_timestamp(@timestamp) %>
    </.tooltip>
    """
  end

  attr(:id, :string, required: true)
  attr(:size, :integer, required: true)

  def trace_memory_info(assigns) do
    ~H"""
    <.tooltip
      id={@id <> "-memory-tooltip"}
      content="Size of the diff sent to browser"
      class="min-w-11"
    >
      <span class={["text-nowrap", get_size_warning_class(@size)]}>
        <%= Memory.bytes_to_pretty_string(@size) %>
      </span>
    </.tooltip>
    """
  end

  attr(:id, :string, required: true)
  attr(:execution_time, :integer, required: true)
  attr(:phx_hook, :string, default: nil)

  def trace_execution_time_info(assigns) do
    ~H"""
    <.tooltip
      id={@id <> "-exec-time-tooltip"}
      content="Execution time of the callback"
      class="min-w-11"
    >
      <span
        id={@id <> "-exec-time"}
        class={["text-nowrap", get_threshold_class(@execution_time)]}
        phx-hook={@phx_hook}
      >
        <%= Parsers.parse_elapsed_time(@execution_time) %>
      </span>
    </.tooltip>
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

  defp get_size_warning_class(size) do
    cond do
      size >= 1.0 * Memory.megabyte() -> "text-error-text"
      size >= 0.4 * Memory.megabyte() -> "text-warning-text"
      true -> ""
    end
  end
end
