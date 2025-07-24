defmodule LiveDebuggerRefactor.App.Debugger.Web.Components.ElixirDisplay do
  @moduledoc """
  This module provides a component to display a tree of terms.
  Check `LiveDebuggerRefactor.App.Utils.TermParser`.
  """

  use LiveDebuggerRefactor.App.Web, :component

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
        <span class={"whitespace-pre #{text_item_color_class(item)}"}><%= item.text %></span>
      <% end %>
    </div>
    """
  end

  defp text_item_color_class(item) do
    if item.color, do: "#{item.color}", else: ""
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
