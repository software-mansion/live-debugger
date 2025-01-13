defmodule LiveDebugger.Components.Trace do
  @moduledoc """
  This module provides a LiveComponent to display a trace.
  """

  use LiveDebuggerWeb, :component

  alias LiveDebugger.Components.Collapsible
  alias LiveDebugger.Components.Tooltip
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.LiveComponents.ElixirDisplay

  attr(:id, :string, required: true)
  attr(:trace, :map, required: true, doc: "The Trace struct to render")

  def trace(assigns) do
    ~H"""
    <Collapsible.collapsible id={@id} icon="hero-chevron-down-micro" chevron_class="text-swm-blue">
      <:label>
        <div class="w-full flex justify-between">
          <Tooltip.tooltip
            position="top"
            content={"#{@trace.module}.#{@trace.function}/#{@trace.arity}"}
          >
            <p class="text-swm-blue font-medium">{@trace.function}/{@trace.arity}</p>
          </Tooltip.tooltip>
          <p class="w-32">{Parsers.parse_timestamp(@trace.timestamp)}</p>
        </div>
      </:label>

      <div class="flex flex-col gap-4 overflow-x-auto h-[30vh] max-h-max overflow-y-auto border-2 border-gray-200 p-2 rounded-lg text-gray-600">
        <%= for args <- @trace.args do %>
          <.live_component
            id={to_string(:erlang.ref_to_list(:erlang.make_ref()))}
            module={ElixirDisplay}
            node={ElixirDisplay.to_node(args, [])}
            level={1}
          />
        <% end %>
      </div>
    </Collapsible.collapsible>
    """
  end
end
