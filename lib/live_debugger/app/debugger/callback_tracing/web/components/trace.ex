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

  alias LiveDebugger.Structs.Trace.ErrorTrace

  alias Phoenix.LiveView.JS

  @doc """
  Displays the label of the trace with a polymorphic composition.
  """

  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)
  attr(:show_subtitle?, :boolean, default: false)
  attr(:search_phrase, :string, default: nil)
  attr(:short_content_full?, :boolean, default: false)
  attr(:fullscreen?, :boolean, default: false)

  def trace_label(assigns) do
    short_content = TraceDisplay.short_content(assigns.trace_display, assigns.short_content_full?)
    assigns = assign(assigns, :short_content, short_content)

    ~H"""
    <div id={@id} class="w-[90%] grow grid items-center gap-x-3 ml-2 grid-cols-[auto_1fr_auto]">
      <.trace_subtitle
        :if={@show_subtitle? and not is_nil(@trace_display.subtitle)}
        id={@id <> "-subtitle"}
        subtitle={@trace_display.subtitle}
        subtitle_link_data={@trace_display.subtitle_link_data}
        fullscreen?={@fullscreen?}
      />
      <.trace_title title={@trace_display.title} />

      <.trace_short_content
        :if={!@fullscreen?}
        id={@id <> "-short-content"}
        short_content={@short_content}
        search_phrase={@search_phrase}
      />

      <.trace_side_section_wrapper>
        <.trace_side_section_left
          id={@id <> "-side-section-left"}
          side_section_left={@trace_display.side_section_left}
          fullscreen?={@fullscreen?}
        />
        <.trace_side_section_separator />
        <.trace_side_section_right
          id={@id <> "-side-section-right"}
          side_section_right={@trace_display.side_section_right}
          from_event?={@trace_display.from_event?}
          fullscreen?={@fullscreen?}
        />
      </.trace_side_section_wrapper>

      <div :if={@trace_display.error} class="col-span-full w-full">
        <.trace_error_message error={@trace_display.error} />
      </div>
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
  attr(:fullscreen?, :boolean, default: false)

  def trace_body_navbar_wrapper(assigns) do
    assigns =
      assigns
      |> assign(:error, assigns.trace_display.error)
      |> assign(:group_name, "error-trace-tabs-#{assigns.id}")

    ~H"""
    <div id={@id <> "wrapper"} class="flex flex-col w-full">
      <%= if @error do %>
        <input
          type="radio"
          name={@group_name}
          id={@id <> "-tab-1"}
          class="peer/content hidden"
          checked
        />
        <input type="radio" name={@group_name} id={@id <> "-tab-2"} class="peer/stack hidden" />
        <input type="radio" name={@group_name} id={@id <> "-tab-3"} class="peer/raw hidden" />

        <div class={[
          "flex flex-row gap-6 border-b border-default-border mb-2 text-sm select-none sticky top-0 z-10 bg-navbar-bg min-w-[420px]",
          "items-center",
          if(@fullscreen?, do: "px-4", else: "pl-4"),
          "peer-checked/content:[&_.tab-content]:text-navbar-selected-bg peer-checked/content:[&_.tab-content]:border-navbar-selected-bg",
          "peer-checked/stack:[&_.tab-stack]:text-navbar-selected-bg peer-checked/stack:[&_.tab-stack]:border-navbar-selected-bg",
          "peer-checked/raw:[&_.tab-raw]:text-navbar-selected-bg peer-checked/raw:[&_.tab-raw]:border-navbar-selected-bg",
          "peer-checked/stack:[&_.copy-btn-stack]:block",
          "peer-checked/raw:[&_.copy-btn-raw]:block"
        ]}>
          <label
            for={@id <> "-tab-1"}
            class="tab-content cursor-pointer pb-3 pt-3 px-1 border-b border-transparent -mb-px text-secondary-text transition-colors hover:text-navbar-selected-bg font-medium"
          >
            Trace Body
          </label>

          <div class="flex items-center gap-2">
            <label
              for={@id <> "-tab-2"}
              class="tab-stack cursor-pointer pb-3 pt-3 px-1 border-b border-transparent -mb-px text-secondary-text transition-colors hover:text-navbar-selected-bg font-medium"
            >
              Stacktrace
            </label>
          </div>

          <div class="flex items-center gap-2">
            <label
              for={@id <> "-tab-3"}
              class="tab-raw cursor-pointer pb-3 pt-3 px-1 border-b border-transparent -mb-px text-secondary-text transition-colors hover:text-navbar-selected-bg font-medium"
            >
              Raw Error
            </label>
          </div>
          <div class="flex items-center ml-auto">
            <div class="copy-btn-stack hidden">
              <.copy_button
                id={"#{@id}-copy-stack"}
                value={@error.stacktrace}
                variant="icon-button"
                title="Copy Stacktrace"
                class="text-secondary-text hover:text-primary-text"
                fullscreen?={@fullscreen?}
              />
            </div>

            <div class="copy-btn-raw hidden">
              <.copy_button
                id={"#{@id}-copy-raw"}
                value={@error.raw_error}
                variant="icon-button"
                title="Copy Raw Error"
                class="text-secondary-text hover:text-primary-text"
                fullscreen?={@fullscreen?}
              />
            </div>

            <.fullscreen_button
              id={"trace-fullscreen-#{@id}"}
              class="m-2"
              phx-click="open-trace"
              phx-value-trace-id={@trace_display.id}
            />
          </div>
        </div>

        <div class="hidden peer-checked/content:block px-4 pt-4 overflow-y-auto pb-4">
          <.trace_body id={@id} trace_display={@trace_display} search_phrase={@search_phrase} />
        </div>

        <div class="hidden peer-checked/stack:block">
          <pre
            data-testid="stacktrace"
            class={[
              "block w-full",
              "max-h-[30vh] overflow-y-auto overflow-x-auto",
              "whitespace-pre",
              "text-xs p-4",
              "font-code bg-navbar-bg",
              "overscroll-y-contain"
            ]}
          ><%= format_stacktrace(@error.stacktrace) %></pre>
        </div>

        <div class="hidden peer-checked/raw:block">
          <pre
            data-testid="raw_error"
            class={[
              "block w-full",
              "whitespace-pre",
              "text-xs p-4",
              "overflow-y-auto overflow-x-auto max-h-[30vh]",
              "font-code bg-navbar-bg",
              "overscroll-y-contain"
            ]}
          ><%=@error.raw_error%></pre>
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
  attr(:page, :atom, required: true, values: [:node_inspector, :global_callbacks])

  def trace_fullscreen(assigns) do
    ~H"""
    <.fullscreen id={@id} title={@displayed_trace.title}>
      <:header>
        <div class={[
          "text-primary-text font-semibold p-4 rounded flex items-center flex col justify-between border-b",
          header_type(@displayed_trace)
        ]}>
          <.trace_label
            id={@id <> "-fullscreen-label"}
            trace_display={@displayed_trace}
            short_content_full?={false}
            show_subtitle?={if @page == :global_callbacks, do: true, else: false}
            fullscreen?={true}
          />
          <.icon_button
            id={"#{@id}-close"}
            phx-click={JS.dispatch("close", to: "##{@id}")}
            icon="icon-cross"
            variant="secondary"
          />
        </div>
      </:header>
      <div class={[
        "flex flex-col gap-4 items-start justify-center hover:[&>div>div>div>button]:hidden",
        if(is_nil(@displayed_trace.error), do: "p-4", else: "[&>div>div>div>div>button]:hidden")
      ]}>
        <.trace_body_navbar_wrapper
          id={@id <> "-fullscreen"}
          trace_display={@displayed_trace}
          search_phrase={@search_phrase}
          fullscreen?={true}
        />
      </div>
    </.fullscreen>
    """
  end

  attr(:id, :string, required: true)
  attr(:subtitle, :string, required: true)
  attr(:subtitle_link_data, :map, default: nil)
  attr(:fullscreen?, :boolean, default: false)

  defp trace_subtitle(assigns) do
    ~H"""
    <div class="text-primary text-2xs font-normal truncate col-span-3">
      <.tooltip
        id={@id <> "-tooltip"}
        content="See in Node Inspector"
        class="w-max"
        fullscreen?={@fullscreen?}
      >
        <.link
          class="block hover:underline"
          patch={
            RoutesHelper.debugger_node_inspector(@subtitle_link_data.pid,
              cid: @subtitle_link_data.cid
            )
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
  attr(:fullscreen?, :boolean, default: false)

  defp trace_side_section_left(%{side_section_left: {:timestamp, timestamp}} = assigns) do
    assigns = assign(assigns, :timestamp, timestamp)

    ~H"""
    <.tooltip id={@id <> "-tooltip"} content="Timestamp" class="min-w-12" fullscreen?={@fullscreen?}>
      <%= Parsers.parse_timestamp(@timestamp) %>
    </.tooltip>
    """
  end

  attr(:id, :string, required: true)
  attr(:side_section_right, :any, required: true)
  attr(:from_event?, :boolean, required: true)
  attr(:fullscreen?, :boolean, default: false)

  defp trace_side_section_right(%{side_section_right: {:execution_time, time}} = assigns) do
    assigns = assign(assigns, :execution_time, time)

    ~H"""
    <.tooltip
      id={@id <> "-tooltip"}
      content="Execution time of the callback"
      class="min-w-11"
      fullscreen?={@fullscreen?}
    >
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
    <.tooltip
      id={@id <> "-tooltip"}
      content="Size of the diff sent to browser"
      class="min-w-11"
      fullscreen?={@fullscreen?}
    >
      <span class={["text-nowrap", get_size_warning_class(@size)]}>
        <%= Memory.bytes_to_pretty_string(@size) %>
      </span>
    </.tooltip>
    """
  end

  attr(:error, ErrorTrace, required: true)

  defp trace_error_message(assigns) do
    ~H"""
    <div class="flex flex-row gap-2 mt-1 text-error-text items-center">
      <.icon name="icon-info" class="w-4 h-4 shrink-0" />
      <p :if={@error}><%= clean_error_message(@error.message) %></p>
    </div>
    """
  end

  defp clean_error_message(message) do
    message
    |> String.replace("**", "")
    |> String.trim()
  end

  defp format_stacktrace(stacktrace) do
    stacktrace
    |> String.split("\n")
    |> Enum.map_join("\n", &String.trim/1)
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

  defp header_type(%{error: error}) when not is_nil(error), do: "bg-error-bg border-error-border"
  defp header_type(%{type: :diff}), do: "bg-surface-1-bg border-diff-border"
  defp header_type(_), do: "bg-surface-1-bg border-default-border"
end
