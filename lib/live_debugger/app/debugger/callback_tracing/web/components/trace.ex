defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.Components.Trace do
  @moduledoc """
  UI components for the traces.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplay
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.Utils.Memory
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper

  alias LiveDebugger.Structs.Trace.TraceError

  @doc """
  Displays the label of the trace with a polymorphic composition.
  """

  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)
  attr(:show_subtitle?, :boolean, default: false)
  attr(:search_phrase, :string, default: nil)
  attr(:short_content_full?, :boolean, default: false)

  def trace_label(assigns) do
    short_content = TraceDisplay.short_content(assigns.trace_display, assigns.short_content_full?)
    assigns = assign(assigns, :short_content, short_content)

    ~H"""
    <div class="flex flex-col">
      <div id={@id} class="w-[90%] grow grid items-center gap-x-3 ml-2 grid-cols-[auto_1fr_auto]">
        <.trace_subtitle
          :if={@show_subtitle? and not is_nil(@trace_display.subtitle)}
          id={@id <> "-subtitle"}
          subtitle={@trace_display.subtitle}
          subtitle_link_data={@trace_display.subtitle_link_data}
        />

        <.trace_title title={@trace_display.title} />

        <.trace_short_content
          id={@id <> "-short-content"}
          short_content={@short_content}
          search_phrase={@search_phrase}
        />

        <.trace_side_section_wrapper>
          <.trace_side_section_left
            id={@id <> "-side-section-left"}
            side_section_left={@trace_display.side_section_left}
          />
          <.trace_side_section_separator />
          <.trace_side_section_right
            id={@id <> "-side-section-right"}
            side_section_right={@trace_display.side_section_right}
            from_event?={@trace_display.from_event?}
          />
        </.trace_side_section_wrapper>
      </div>
      <.trace_error_message :if={@trace_display.error} error={@trace_display.error} />
    </div>
    """
  end

  @doc """
  Displays the body of the trace.
  """
  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)
  attr(:search_phrase, :string, required: true)

  def trace_body(assigns) do
    ~H"""
    <div
      id={@id}
      class="flex flex-col gap-4 w-full"
      phx-hook="TraceBodySearchHighlight"
      data-search_phrase={@search_phrase}
    >
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

  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)
  attr(:search_phrase, :string, required: true)

  def trace_body_navbar_wrapper(assigns) do
    assigns = assign(assigns, :error, assigns.trace_display.error)

    ~H"""
    <div id={@id <> "wrapper"} class="flex flex-col gap-4 w-full">
      <%= if @error do %>
        <% group_name = "error-trace-tabs-#{@id}" %>

        <input
          type="radio"
          name={group_name}
          id={@id <> "-tab-1"}
          class="peer/content hidden"
          checked
        />
        <input type="radio" name={group_name} id={@id <> "-tab-2"} class="peer/stack hidden" />
        <input type="radio" name={group_name} id={@id <> "-tab-3"} class="peer/raw hidden" />

        <div class={[
          "flex flex-row gap-4 border-b border-default-border mb-2 text-sm select-none",
          "peer-checked/content:[&>label:nth-of-type(1)]:text-navbar-selected-bg",
          "peer-checked/content:[&>label:nth-of-type(1)]:border-navbar-selected-bg",
          "peer-checked/stack:[&>label:nth-of-type(2)]:text-navbar-selected-bg",
          "peer-checked/stack:[&>label:nth-of-type(2)]:border-navbar-selected-bg",
          "peer-checked/raw:[&>label:nth-of-type(3)]:text-navbar-selected-bg",
          "peer-checked/raw:[&>label:nth-of-type(3)]:border-navbar-selected-bg"
        ]}>
          <label
            for={@id <> "-tab-1"}
            class="cursor-pointer pb-2 px-1 border-b-2 border-transparent text-secondary-text transition-colors hover:text-primary-text font-medium"
          >
            Trace Body
          </label>

          <label
            for={@id <> "-tab-2"}
            class="cursor-pointer pb-2 px-1 border-b-2 border-transparent text-secondary-text transition-colors hover:text-primary-text font-medium"
          >
            Stacktrace
          </label>

          <label
            for={@id <> "-tab-3"}
            class="cursor-pointer pb-2 px-1 border-b-2 border-transparent text-secondary-text transition-colors hover:text-primary-text font-medium"
          >
            Raw Error
          </label>
        </div>

        <div class="hidden peer-checked/content:block">
          <.trace_body id={@id} trace_display={@trace_display} search_phrase={@search_phrase} />
        </div>

        <div class="hidden peer-checked/stack:block">
          <div class="flex flex-col gap-2">
            <pre class="whitespace-pre-wrap break-words text-xs font-mono p-2 overflow-x-auto">
              {@error.stacktrace}
            </pre>
          </div>
        </div>

        <div class="hidden peer-checked/raw:block">
          <div class="flex flex-col gap-2">
            <pre class="whitespace-pre-wrap break-words text-xs font-mono p-2 overflow-x-auto">
              {@error.raw_error}
            </pre>
          </div>
        </div>
      <% else %>
        <.trace_body id={@id} trace_display={@trace_display} search_phrase={@search_phrase} />
      <% end %>
    </div>
    """
  end

  @doc """
  Displays the fullscreen of the trace.
  """
  attr(:id, :string, required: true)
  attr(:displayed_trace, TraceDisplay, required: true)
  attr(:search_phrase, :string, required: true)

  def trace_fullscreen(assigns) do
    ~H"""
    <.fullscreen id={@id} title={@displayed_trace.title}>
      <div class="p-4 flex flex-col gap-4 items-start justify-center hover:[&>div>div>div>button]:hidden">
        <.trace_body_navbar_wrapper
          id={@id <> "-fullscreen"}
          trace_display={@displayed_trace}
          search_phrase={@search_phrase}
        />
      </div>
    </.fullscreen>
    """
  end

  attr(:id, :string, required: true)
  attr(:subtitle, :string, required: true)
  attr(:subtitle_link_data, :map, default: nil)

  defp trace_subtitle(assigns) do
    ~H"""
    <div class="text-primary text-2xs font-normal truncate col-span-3">
      <.tooltip id={@id <> "-tooltip"} content="See in Node Inspector" class="w-max">
        <.link
          class="block hover:underline"
          patch={
            RoutesHelper.debugger_node_inspector(@subtitle_link_data.pid, @subtitle_link_data.cid)
          }
        >
          <%= @subtitle %>
        </.link>
      </.tooltip>
    </div>
    """
  end

  attr(:title, :string, required: true)

  defp trace_title(assigns) do
    ~H"""
    <p class="font-medium text-sm">
      <%= @title %>
    </p>
    """
  end

  attr(:id, :string, default: nil)
  attr(:short_content, :string, required: true)
  attr(:search_phrase, :string, required: true)

  defp trace_short_content(assigns) do
    ~H"""
    <div class="grow shrink text-secondary-text font-code font-normal text-3xs truncate">
      <div class="hidden @[30rem]/traces:flex">
        <p
          id={if(@id, do: @id <> "-short-content", else: false)}
          class="hide-on-open mt-0.5"
          phx-hook="TraceLabelSearchHighlight"
          data-search_phrase={@search_phrase}
        >
          <%= @short_content %>
        </p>
      </div>
    </div>
    """
  end

  slot(:inner_block, required: true)

  defp trace_side_section_wrapper(assigns) do
    ~H"""
    <div class="flex text-xs font-normal text-secondary-text align-center">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp trace_side_section_separator(assigns) do
    ~H"""
    <span class="mx-2 border-r border-default-border"></span>
    """
  end

  attr(:id, :string, required: true)
  attr(:side_section_left, :any, required: true)

  defp trace_side_section_left(%{side_section_left: {:timestamp, timestamp}} = assigns) do
    assigns = assign(assigns, :timestamp, timestamp)

    ~H"""
    <.tooltip id={@id <> "-tooltip"} content="timestamp" class="min-w-24">
      <%= Parsers.parse_timestamp(@timestamp) %>
    </.tooltip>
    """
  end

  attr(:id, :string, required: true)
  attr(:side_section_right, :any, required: true)
  attr(:from_event?, :boolean, required: true)

  defp trace_side_section_right(%{side_section_right: {:execution_time, time}} = assigns) do
    assigns = assign(assigns, :execution_time, time)

    ~H"""
    <.tooltip id={@id <> "-tooltip"} content="Execution time of the callback" class="min-w-11">
      <span
        id={@id <> "-value"}
        class={["text-nowrap", get_threshold_class(@execution_time)]}
        phx-hook={if @from_event?, do: "TraceExecutionTime", else: nil}
      >
        <%= Parsers.parse_elapsed_time(@execution_time) %>
      </span>
    </.tooltip>
    """
  end

  defp trace_side_section_right(%{side_section_right: {:size, size}} = assigns) do
    assigns = assign(assigns, :size, size)

    ~H"""
    <.tooltip id={@id <> "-tooltip"} content="Size of the diff sent to browser" class="min-w-11">
      <span class={["text-nowrap", get_size_warning_class(@size)]}>
        <%= Memory.bytes_to_pretty_string(@size) %>
      </span>
    </.tooltip>
    """
  end

  attr(:error, TraceError, required: true)

  defp trace_error_message(assigns) do
    ~H"""
    <div class="flex flex-row mt-2 text-red-600">
      <.icon name="icon-info" class="w-4 h-4" />
      <p :if={@error}>{@error.message}</p>
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

  defp get_size_warning_class(size) do
    cond do
      size >= 1.0 * Memory.megabyte() -> "text-error-text"
      size >= 0.4 * Memory.megabyte() -> "text-warning-text"
      true -> ""
    end
  end
end
