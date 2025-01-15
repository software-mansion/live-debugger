defmodule LiveDebugger.Components do
  @moduledoc """
  This module provides reusable components for LiveDebugger.
  """

  use LiveDebuggerWeb, :component

  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Utils.TermParser

  attr(:id, :string, required: true)
  attr(:trace, :map, required: true, doc: "The Trace struct to render")

  def trace(assigns) do
    ~H"""
    <.collapsible id={@id} icon="hero-chevron-down-micro" chevron_class="text-swm-blue">
      <:label>
        <div class="w-full flex justify-between">
          <.tooltip position="top" content={"#{@trace.module}.#{@trace.function}/#{@trace.arity}"}>
            <p class="text-swm-blue font-medium">{@trace.function}/{@trace.arity}</p>
          </.tooltip>
          <p class="w-32">{Parsers.parse_timestamp(@trace.timestamp)}</p>
        </div>
      </:label>

      <div class="flex flex-col gap-4 overflow-x-auto h-[30vh] max-h-max overflow-y-auto border-2 border-gray-200 p-2 rounded-lg text-gray-600">
        <%= for {args, index} <- Enum.with_index(@trace.args) do %>
          <.live_component
            id={@id <> "-#{index}"}
            module={LiveDebugger.LiveComponents.ElixirDisplay}
            node={TermParser.term_to_display_tree(args)}
            level={1}
          />
        <% end %>
      </div>
    </.collapsible>
    """
  end

  attr(:id, :string, required: true)
  attr(:class, :any, default: nil, doc: "CSS class for parent container")
  attr(:chevron_class, :string, default: nil, doc: "CSS class for the chevron icon")
  attr(:icon, :string, default: "hero-chevron-down-solid", doc: "Icon name")
  attr(:open, :boolean, default: false, doc: "Whether the collapsible is open by default")
  attr(:rest, :global)

  slot(:label, required: true)
  slot(:inner_block, required: true)

  def collapsible(assigns) do
    ~H"""
    <div id={@id} class={@class} {@rest} x-data={"{ expanded: #{@open} }"}>
      <div data-open={if @open, do: "true", else: "false"}>
        <div id={content_panel_header_id(@id)} class="flex items-center gap-1">
          <.custom_icon_button open={@open} id={@id} icon={@icon} chevron_class={@chevron_class} />
          {render_slot(@label)}
        </div>
        <.content_container id={@id}>
          {render_slot(@inner_block)}
        </.content_container>
      </div>
    </div>
    """
  end

  @doc """
  Renders a tooltip using Tooltip hook.
  """
  attr(:content, :string, default: nil)
  attr(:position, :string, default: "bottom", values: ["top", "bottom"])
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def tooltip(assigns) do
    assigns = assign(assigns, :id, "tooltip_" <> Ecto.UUID.generate())

    ~H"""
    <div id={@id} phx-hook="Tooltip" data-tooltip={@content} data-position={@position} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def error_component(assigns) do
    ~H"""
    <div class="h-full flex flex-col items-center justify-center mx-8">
      <.icon name="hero-exclamation-circle" class="w-16 h-16" />
      <.h2 class="text-center">Unexpected error</.h2>
      <.h5 class="text-center">
        Debugger encountered unexpected error - check logs for more
      </.h5>
    </div>
    """
  end

  attr(:socket, :any, required: true)

  def not_found_component(assigns) do
    ~H"""
    <div class="h-full flex flex-col items-center justify-center mx-8">
      <.icon name="hero-exclamation-circle" class="w-16 h-16" />
      <.h2 class="text-center">Debugger disconnected</.h2>
      <.h5 class="text-center">
        We couldn't find any LiveView associated with the given socket id
      </.h5>
      <.link class="text-gray-600 underline" navigate={live_debugger_base_url(@socket)}>
        See available LiveSessions
      </.link>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:chevron_class, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:open, :boolean, required: true)

  defp custom_icon_button(assigns) do
    ~H"""
    <button
      type="button"
      x-on:click="expanded = !expanded"
      aria-expanded="expanded"
      aria-controls={content_panel_id(@id)}
    >
      <.icon
        name={@icon}
        class={[@chevron_class, if(@open, do: "rotate-180")]}
        {%{":class": "{'rotate-180': expanded}"}}
      />
    </button>
    """
  end

  attr(:id, :string, required: true)
  slot(:inner_block)

  defp content_container(assigns) do
    ~H"""
    <div
      id={content_panel_id(@id)}
      role="region"
      aria-labelledby={content_panel_header_id(@id)}
      x-show="expanded"
      x-cloak={true}
      x-collapse={true}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp content_panel_header_id(id), do: "collapsible-header-#{id}"
  defp content_panel_id(id), do: "collapsible-content-panel-#{id}"
end
