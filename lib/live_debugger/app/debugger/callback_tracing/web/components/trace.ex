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
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Structs.DiffTrace
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents
  alias LiveDebugger.Utils.Memory

  @doc """
  Fullscreen modal with trace body.
  """
  attr(:id, :string, required: true)
  attr(:trace, Trace, required: true)
  attr(:rest, :global)

  def trace_fullscreen(assigns) do
    assigns = assign(assigns, :callback_name, Trace.callback_name(assigns.trace))

    ~H"""
    <.fullscreen id={@id} title={@callback_name}>
      <div class="p-4 flex flex-col gap-4 items-start justify-center hover:[&>div>div>div>button]:hidden">
        <.trace_body id={@id <> "-fullscreen"} trace={@trace} {@rest} />
      </div>
    </.fullscreen>
    """
  end

  @doc """
  List of trace's args.
  """
  attr(:id, :string, required: true)
  attr(:trace, Trace, required: true)
  attr(:rest, :global)

  def trace_body(assigns) do
    ~H"""
    <div id={@id <> "-body"} class="flex flex-col gap-4 w-full" {@rest}>
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
    </div>
    """
  end

  @doc """
  Module of the trace.
  """
  attr(:id, :string, required: true)
  attr(:trace, Trace, required: true)
  attr(:class, :string, default: "")

  def module(assigns) do
    ~H"""
    <div class={["text-primary text-2xs font-normal truncate", @class]}>
      <.tooltip id={"#{@id}-trace-module"} content="See in Node Inspector" class="w-max">
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

  @doc """
  Callback name of the trace.
  """
  attr(:trace, Trace, required: true)

  def callback_name(assigns) do
    assigns = assign(assigns, :content, Trace.callback_name(assigns.trace))

    ~H"""
    <.trace_title content={@content} />
    """
  end

  attr(:id, :string, default: nil)
  attr(:trace, Trace, required: true)
  attr(:full, :boolean, default: false)
  attr(:rest, :global)

  def short_trace_content(assigns) do
    assigns =
      assigns
      |> assign(
        content:
          Enum.map_join(
            assigns.trace.args,
            " ",
            &inspect(&1, limit: if(assigns.full, do: :infinity, else: 10), structs: false)
          )
      )

    ~H"""
    <.short_content id={@id} content={@content} {@rest} />
    """
  end

  @doc """
  Timestamp and execution time of the trace.
  """
  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)

  def trace_time_info(assigns) do
    ~H"""
    <div class="flex text-xs font-normal text-secondary-text align-center">
      <.timestamp_info id={@id} timestamp={@trace_display.trace.timestamp} />
      <span class="mx-2 border-r border-default-border"></span>
      <.execution_time_info
        id={@id}
        execution_time={@trace_display.trace.execution_time}
        class={get_threshold_class(@trace_display.trace.execution_time)}
        phx_hook={if @trace_display.from_event?, do: "TraceExecutionTime", else: nil}
      />
    </div>
    """
  end

  @doc """
  Diff trace component for displaying LiveView diffs.
  """
  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)
  attr(:rest, :global)

  def diff_trace(assigns) do
    assigns =
      assigns
      |> assign(
        diff_content: inspect(assigns.trace_display.trace.body, limit: 10, structs: false)
      )

    ~H"""
    <HookComponents.TraceWrapper.render id={@id} trace_display={@trace_display} {@rest}>
      <:label class="grid-cols-[auto_1fr_auto]">
        <.trace_title content="Diff sent" class="font-medium text-sm font-bold" />
        <.short_content id={@id} content={@diff_content} />
        <div class="flex text-xs font-normal text-secondary-text align-center">
          <.timestamp_info id={@id} timestamp={@trace_display.trace.timestamp} />
          <span class="mx-2 border-r border-default-border"></span>
          <.memory_info id={@id} size={@trace_display.trace.size} />
        </div>
      </:label>
      <:body>
        <.diff_trace_body id={@id} trace={@trace_display.trace} />
      </:body>
    </HookComponents.TraceWrapper.render>
    """
  end

  attr(:id, :string, required: true)
  attr(:trace, DiffTrace, required: true)
  attr(:rest, :global)

  defp diff_trace_body(assigns) do
    ~H"""
    <div id={@id <> "-body"} class="flex flex-col gap-4 w-full" {@rest}>
      <div class="flex flex-col gap-4 w-full [&>div>div>button]:hidden hover:[&>div>div>button]:block">
        <div class="shrink-0 flex gap-2 items-center h-4">
          <p class="font-semibold">
            Diff content
          </p>
          <.copy_button id={"#{@id}-diff"} value={TermParser.term_to_copy_string(@trace.body)} />
        </div>
        <ElixirDisplay.term
          id={@id <> "-diff-content"}
          node={TermParser.term_to_display_tree(@trace.body)}
          level={1}
        />
      </div>
    </div>
    """
  end

  attr(:content, :string, required: true)
  attr(:class, :string, default: "font-medium text-sm")

  defp trace_title(assigns) do
    ~H"""
    <p class={@class}><%= @content %></p>
    """
  end

  attr(:id, :string, default: nil)
  attr(:content, :string, required: true)
  attr(:rest, :global)

  defp short_content(assigns) do
    ~H"""
    <div class="grow shrink text-secondary-text font-code font-normal text-3xs truncate">
      <div class="hidden @[30rem]/traces:flex">
        <p id={if(@id, do: @id <> "-short-content", else: false)} class="hide-on-open mt-0.5" {@rest}>
          <%= @content %>
        </p>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:timestamp, :integer, required: true)

  defp timestamp_info(assigns) do
    ~H"""
    <.tooltip id={@id <> "-timestamp-tooltip"} content="timestamp" class="min-w-24">
      <%= Parsers.parse_timestamp(@timestamp) %>
    </.tooltip>
    """
  end

  attr(:id, :string, required: true)
  attr(:size, :integer, required: true)

  defp memory_info(assigns) do
    ~H"""
    <.tooltip
      id={@id <> "-memory-tooltip"}
      content="Size of the diff sent to browser"
      class="min-w-11"
    >
      <span class="text-nowrap">
        <%= Memory.bytes_to_pretty_string(@size) %>
      </span>
    </.tooltip>
    """
  end

  attr(:id, :string, required: true)
  attr(:execution_time, :integer, required: true)
  attr(:class, :string, default: "")
  attr(:phx_hook, :string, default: nil)

  def execution_time_info(assigns) do
    ~H"""
    <.tooltip
      id={@id <> "-exec-time-tooltip"}
      content="Execution time of the callback"
      class="min-w-11"
    >
      <span id={@id <> "-exec-time"} class={["text-nowrap", @class]} phx-hook={@phx_hook}>
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
end
