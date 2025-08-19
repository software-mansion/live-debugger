defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.Components.Trace do
  @moduledoc """
  UI components for the traces.
  """

  use LiveDebuggerRefactor.App.Web, :component

  alias LiveDebuggerRefactor.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebuggerRefactor.App.Debugger.CallbackTracing.Structs.TraceDisplay
  alias LiveDebuggerRefactor.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebuggerRefactor.App.Utils.Parsers
  alias LiveDebuggerRefactor.App.Utils.TermParser
  alias LiveDebuggerRefactor.Structs.Trace

  @doc """
  Fullscreen modal with trace body.
  """
  attr(:id, :string, required: true)
  attr(:trace, Trace, required: true)

  def trace_fullscreen(assigns) do
    assigns = assign(assigns, :callback_name, Trace.callback_name(assigns.trace))

    ~H"""
    <.fullscreen id={@id} title={@callback_name}>
      <div class="w-full flex flex-col gap-4 items-start justify-center hover:[&>div>div>div>button]:hidden">
        <.trace_body id={@id <> "-fullscreen"} trace={@trace} />
      </div>
    </.fullscreen>
    """
  end

  @doc """
  List of trace's args.
  """
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
  attr(:search_phrase, :string, default: "")

  def callback_name(%{search_phrase: ""} = assigns) do
    assigns = assign(assigns, :content, Trace.callback_name(assigns.trace))

    ~H"""
    <p class="font-medium text-sm"><%= @content %></p>
    """
  end

  def callback_name(assigns) do
    search_regex = ~r/#{Regex.escape(assigns.search_phrase)}/i
    parts = Trace.callback_name(assigns.trace) |> get_parts(search_regex, trim: true)

    dbg(parts)

    assigns = assign(assigns, :parts, parts)

    ~H"""
    <p class="font-medium text-sm">
      <%= for text <- @parts do %>
        <%= if text =~ search_regex do %>
          <mark><%= text %></mark>
        <% else %>
          <%= text %>
        <% end %>
      <% end %>
    </p>
    """
  end

  attr(:trace, Trace, required: true)
  attr(:search_phrase, :string, default: "")

  def short_trace_content(%{search_phrase: _} = assigns) do
    assigns =
      assign(
        assigns,
        :content,
        Enum.map_join(assigns.trace.args, " ", &inspect(&1, limit: :infinity, structs: false))
      )

    ~H"""
    <div class="grow shrink text-secondary-text font-code font-normal text-3xs truncate">
      <p class="hide-on-open mt-0.5"><%= @content %></p>
    </div>
    """
  end

  def short_trace_content(assigns) do
    search_regex = ~r/#{Regex.escape(assigns.search_phrase)}/i

    parts =
      assigns.trace.args
      |> Enum.map_join(" ", &inspect(&1, limit: :infinity, structs: false))
      |> get_parts(search_regex)

    assigns = assign(assigns, parts: parts)

    ~H"""
    <div class="grow shrink text-secondary-text font-code font-normal text-3xs truncate">
      <p class="hide-on-open mt-0.5 whitespace-pre">
        <%= for text <- @parts do %>
          <%= if text =~ search_regex do %>
            <mark><%= text %></mark>
          <% else %>
            <span><%= text %></span>
          <% end %>
        <% end %>
      </p>
    </div>
    """
  end

  defp get_parts(text, search_regex, opts \\ []) do
    parts = text |> String.split(search_regex, [include_captures: true] ++ opts)

    first_part = List.first(parts)

    if String.length(first_part) > 20 do
      ["..." <> String.slice(first_part, -17..-1//1) | tl(parts)]
    else
      parts
    end
  end

  @doc """
  Timestamp and execution time of the trace.
  """
  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)

  def trace_time_info(assigns) do
    ~H"""
    <div class="flex text-xs font-normal text-secondary-text align-center">
      <.tooltip id={@id <> "-timestamp-tooltip"} content="timestamp" class="min-w-24">
        <%= Parsers.parse_timestamp(@trace_display.trace.timestamp) %>
      </.tooltip>
      <span class="mx-2 border-r border-default-border"></span>
      <.tooltip id={@id <> "-exec-time-tooltip"} content="execution time" class="min-w-11">
        <span
          id={@id <> "-exec-time"}
          class={["text-nowrap", get_threshold_class(@trace_display.trace.execution_time)]}
          phx-hook={if @trace_display.from_event?, do: "TraceExecutionTime"}
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
