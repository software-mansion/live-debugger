defmodule LiveDebuggerWeb.Components.Traces do
  @moduledoc """
  UI components for the TracesLive module.
  """

  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Structs.Trace
  alias LiveDebuggerWeb.Components.ElixirDisplay
  alias LiveDebugger.Utils.TermParser

  def refresh_button(assigns) do
    ~H"""
    <.button phx-click="refresh-history" class="flex gap-2" variant="secondary" size="sm">
      <.icon name="icon-refresh" class="w-4 h-4" />
      <div class="hidden @[29rem]/traces:block">Refresh</div>
    </.button>
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
          <div :if={index > 0} class="border-t border-default-border w-full"></div>
          <p class="font-semibold shrink-0">
            Arg <%= index %> (<%= Trace.arg_name(@trace, index) %>)
          </p>
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
