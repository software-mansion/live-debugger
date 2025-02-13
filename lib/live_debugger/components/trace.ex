defmodule LiveDebugger.Components.Trace do
  use LiveDebuggerWeb, :component

  alias LiveDebugger.Components.ElixirDisplay
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Utils.Parsers

  attr(:id, :string, required: true)
  attr(:trace, :map, required: true, doc: "The Trace struct to render")

  def trace(assigns) do
    ~H"""
    <.collapsible id={@id} icon="hero-chevron-right-micro" chevron_class="text-primary">
      <:label>
        <div class="w-full flex justify-between">
          <.tooltip
            id={"trace_" <> @id}
            position="top"
            content={"#{@trace.module}.#{@trace.function}/#{@trace.arity}"}
          >
            <div class="flex gap-4">
              <p class="text-primary font-medium"><%= @trace.function %>/<%= @trace.arity %></p>
              <p
                :if={@trace.counter > 1}
                class="text-sm text-gray-500 italic align-baseline mt-[0.2rem]"
              >
                +<%= @trace.counter - 1 %>
              </p>
            </div>
          </.tooltip>
          <p class="w-32"><%= Parsers.parse_timestamp(@trace.timestamp) %></p>
        </div>
      </:label>

      <div class="relative flex flex-col gap-4 overflow-x-auto h-[30vh] max-h-max overflow-y-auto border-2 border-gray-200 p-2 rounded-lg text-gray-600">
        <.fullscreen_wrapper id={@id <> "-fullscreen"} class="absolute top-0 right-0">
          <div class="w-full flex flex-col items-start justify-center">
            <%= for {args, index} <- Enum.with_index(@trace.args) do %>
              <ElixirDisplay.term
                id={@id <> "-#{index}-fullscreen"}
                node={TermParser.term_to_display_tree(args)}
                level={1}
              />
            <% end %>
          </div>
        </.fullscreen_wrapper>
        <%= for {args, index} <- Enum.with_index(@trace.args) do %>
          <ElixirDisplay.term
            id={@id <> "-#{index}"}
            node={TermParser.term_to_display_tree(args)}
            level={1}
          />
        <% end %>
      </div>
    </.collapsible>
    """
  end
end
