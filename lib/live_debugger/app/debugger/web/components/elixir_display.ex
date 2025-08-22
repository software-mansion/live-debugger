defmodule LiveDebugger.App.Debugger.Web.Components.ElixirDisplay do
  @moduledoc """
  This module provides a component to display a tree of terms.
  Check `LiveDebugger.App.Utils.TermParser`.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Utils.TermParser.DisplayElement
  alias LiveDebugger.App.Utils.TermParser.TermNode

  @max_auto_expand_size 6

  @doc """
  Returns a tree of terms.
  """

  attr(:id, :string, required: true)
  attr(:node, TermNode, required: true)
  attr(:level, :integer, default: 1)

  def term(assigns) do
    assigns =
      assigns
      |> assign(:expanded?, auto_expand?(assigns.node, assigns.level))
      |> assign(:has_children?, has_children?(assigns.node))

    ~H"""
    <div class="font-code">
      <div class="ml-[2ch]">
        <.text_items :if={!@has_children?} items={@node.content} />
      </div>
      <.collapsible
        :if={@has_children?}
        id={@id <> "collapsible"}
        open={@expanded?}
        icon="icon-chevron-right"
        label_class="max-w-max"
        chevron_class="text-code-2 m-auto w-[2ch] h-[2ch]"
      >
        <:label>
          <div class="flex items-center">
            <div class="show-on-open">
              <.text_items items={@node.expanded_before} />
            </div>
            <div class="hide-on-open">
              <.text_items items={@node.content} />
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
        <span class={"#{text_item_color_class(item)}"}>
          <pre data-text_item="true"><%= item.text %></pre>
        </span>
      <% end %>
    </div>
    """
  end

  defp text_item_color_class(%DisplayElement{color: color}) do
    if color, do: "#{color}", else: ""
  end

  defp auto_expand?(%TermNode{}, 1), do: true

  defp auto_expand?(%TermNode{} = node, _level) do
    node.kind == "tuple" and children_number(node) <= @max_auto_expand_size
  end

  defp has_children?(%TermNode{children: []}), do: false
  defp has_children?(%TermNode{}), do: true

  defp children_number(%TermNode{children: nil}), do: 0
  defp children_number(%TermNode{children: children}), do: length(children)
end
