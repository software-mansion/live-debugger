defmodule LiveDebugger.Components.Traces do
  @moduledoc """
  UI components for the TracesLive module.
  """

  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Components.ElixirDisplay
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Utils.Parsers

  attr(:tracing_started?, :boolean, required: true)

  def toggle_tracing_button(assigns) do
    ~H"""
    <.button phx-click="switch-tracing" class="flex gap-2" size="sm">
      <div class="flex gap-1.5 items-center w-12">
        <%= if @tracing_started? do %>
          <.icon name="icon-stop" class="w-4 h-4" />
          <div>Stop</div>
        <% else %>
          <.icon name="icon-play" class="w-3.5 h-3.5" />
          <div>Start</div>
        <% end %>
      </div>
    </.button>
    """
  end

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
        <div
          id={@id <> "-label"}
          class="w-[90%] grow flex items-center ml-2 gap-1.5"
          phx-update="ignore"
        >
          <p class="font-medium text-sm"><%= @callback_name %></p>
          <.short_trace_content trace={@trace} />
          <p class="w-max text-xs font-normal text-secondary-text align-center">
            <%= Parsers.parse_timestamp(@trace.timestamp) %>
          </p>
        </div>
      </:label>
      <div class="relative flex flex-col gap-4 overflow-x-auto max-w-full h-[30vh] max-h-max overflow-y-auto">
        <.fullscreen_button
          id={"trace-fullscreen-#{@id}"}
          class="absolute right-2 top-2"
          phx-click="open-trace"
          phx-value-data={@trace.id}
        />

        <%= if @render_body? do %>
          <%= for {args, index} <- Enum.with_index(@trace.args) do %>
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
    </.collapsible>
    """
  end

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
      <div class="w-full flex flex-col gap-4 items-start justify-center">
        <%= for {args, index} <- Enum.with_index(@trace_args) do %>
          <ElixirDisplay.term
            id={@id <> "-#{index}-fullscreen"}
            node={TermParser.term_to_display_tree(args)}
            level={1}
          />
        <% end %>
      </div>
    </.fullscreen>
    """
  end
end
