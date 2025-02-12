defmodule LiveDebugger.Components.ElixirDisplay do
  @moduledoc """
  This module provides a component to display a tree of terms.
  Check LiveDebugger.Utils.TermParser.
  """

  use LiveDebuggerWeb, :component

  @max_auto_expand_size 6

  @doc """
  Returns a tree of terms.
  """

  attr(:id, :string, required: true)
  attr(:node, :any, required: true)
  attr(:level, :integer, required: true)

  def term(assigns) do
    assigns =
      assigns
      |> assign(:expanded?, auto_expand?(assigns.node, assigns.level))
      |> assign(:has_children?, has_children?(assigns.node))

    ~H"""
    <div class="font-mono text-sm text-gray-500">
      <div class="ml-[2ch]">
        <.text_items :if={!@has_children?} items={@node.content} />
      </div>
      <.collapsible
        :if={@has_children?}
        id={@id <> "collapsible"}
        open={@expanded?}
        icon="hero-chevron-right-micro"
        class="[&>summary_.hide-on-opened]:open:hidden"
        label_class="max-w-max"
        chevron_class="w-[2ch] mr-0"
      >
        <:label>
          <div class="flex items-center">
            <.text_items items={@node.expanded_before} />
            <div class="flex hide-on-opened">
              ... <.text_items items={@node.expanded_after} />
            </div>
          </div>
        </:label>

        <ol class="m-0 ml-[2ch] block list-none p-0">
          <%= for {child, index} <- Enum.with_index(@node.children) do %>
            <li class="flex flex-col">
              <.term id={@id <> "-#{index}"} node={child} level={@level + 1} />
            </li>
          <% end %>
        </ol>
        <div class="ml-[2ch]">
          <.text_items items={@node.expanded_after} />
        </div>
      </.collapsible>
    </div>
    """
  end

  attr(:items, :list, required: true)

  defp text_items(assigns) do
    ~H"""
    <div class="flex">
      <%= for item <- @items do %>
        <span class="whitespace-pre" style={text_items_style(item)}><%= item.text %></span>
      <% end %>
    </div>
    """
  end

  defp text_items_style(item) do
    if item.color, do: "color: #{item.color};", else: ""
  end

  defp auto_expand?(_node, 1), do: true

  defp auto_expand?(node, _level) do
    node.kind == "tuple" and children_number(node) <= @max_auto_expand_size
  end

  defp has_children?(%{children: nil} = _node), do: false
  defp has_children?(_node), do: true

  defp children_number(%{children: nil} = _node), do: 0
  defp children_number(%{children: children}), do: length(children)
end
