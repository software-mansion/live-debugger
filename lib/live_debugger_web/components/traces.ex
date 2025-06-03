defmodule LiveDebuggerWeb.Components.Traces do
  @moduledoc """
  UI components for the TracesLive module.
  """

  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Structs.Trace
  alias LiveDebuggerWeb.Components.ElixirDisplay
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Utils.Parsers

  def clear_button(assigns) do
    ~H"""
    <.button phx-click="clear-traces" class="flex gap-2" variant="secondary" size="sm">
      <.icon name="icon-trash" class="w-4 h-4" />
      <div class="hidden @[29rem]/traces:block">Clear</div>
    </.button>
    """
  end

  def refresh_button(assigns) do
    ~H"""
    <.button phx-click="refresh-history" class="flex gap-2" variant="secondary" size="sm">
      <.icon name="icon-refresh" class="w-4 h-4" />
      <div class="hidden @[29rem]/traces:block">Refresh</div>
    </.button>
    """
  end

  attr(:id, :string, required: true)

  def separator(assigns) do
    ~H"""
    <div id={@id}>
      <div class="h-6 my-1 font-normal text-xs text-secondary-text flex align items-center">
        <div class="border-b border-default-border grow"></div>
        <span class="mx-2">Past Traces</span>
        <div class="border-b border-default-border grow"></div>
      </div>
    </div>
    """
  end

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

  attr(:node_id, :any, required: true)
  attr(:current_filters, :any, required: true)
  attr(:default_filters, :any, required: true)

  def filters_dropdown(assigns) do
    ~H"""
    <.live_component module={LiveDebuggerWeb.LiveComponents.LiveDropdown} id="filters-dropdown">
      <:button>
        <.button class="flex gap-2" variant="secondary" size="sm">
          <.icon name="icon-filters" class="w-4 h-4" />
          <div class="hidden @[29rem]/traces:block">Filters</div>
        </.button>
      </:button>
      <.live_component
        module={LiveDebuggerWeb.LiveComponents.FiltersForm}
        id="filters-form"
        node_id={@node_id}
        filters={@current_filters}
        default_filters={@default_filters}
      />
    </.live_component>
    """
  end

  attr(:id, :string, required: true)
  attr(:existing_traces_status, :atom, required: true)
  attr(:existing_traces, :any, required: true)

  def traces_stream(assigns) do
    ~H"""
    <div id={"#{@id}-stream"} phx-update="stream" class="flex flex-col gap-2">
      <div id={"#{@id}-stream-empty"} class="only:block hidden text-secondary-text">
        <div :if={@existing_traces_status == :ok}>
          No traces have been recorded yet.
        </div>
        <div :if={@existing_traces_status == :loading} class="w-full flex items-center justify-center">
          <.spinner size="sm" />
        </div>
        <.alert
          :if={@existing_traces_status == :error}
          variant="danger"
          with_icon
          heading="Error fetching historical callback traces"
        >
          New events will still be displayed as they come. Check logs for more information
        </.alert>
      </div>
      <%= for {dom_id, wrapped_trace} <- @existing_traces do %>
        <%= if wrapped_trace.id == "separator" do %>
          <.separator id={dom_id} />
        <% else %>
          <.trace id={dom_id} wrapped_trace={wrapped_trace} />
        <% end %>
      <% end %>
    </div>
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

  def get_threshold_class(execution_time) do
    cond do
      execution_time == nil -> ""
      execution_time > 500_000 -> "text-error-text"
      execution_time > 100_000 -> "text-warning-text"
      true -> ""
    end
  end
end
