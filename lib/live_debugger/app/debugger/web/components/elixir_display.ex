defmodule LiveDebugger.App.Debugger.Web.Components.ElixirDisplay do
  @moduledoc """
  This module provides a component to display a tree of terms.
  Check `LiveDebugger.App.Utils.TermParser`.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Utils.TermNode.DisplayElement
  alias LiveDebugger.App.Utils.TermNode

  @doc """
  Returns a tree of terms.
  """

  attr(:id, :string, required: true)
  attr(:node, TermNode, required: true)

  def term(assigns) do
    assigns =
      assigns
      |> assign(:id, "#{assigns.id}-#{assigns.node.id}")
      |> assign(:has_children?, TermNode.has_children?(assigns.node))

    ~H"""
    <div class="font-code">
      <div class="ml-[2ch]">
        <.text_items :if={!@has_children?} items={@node.content} />
      </div>
      <.collapsible
        :if={@has_children?}
        id={@id <> "collapsible"}
        open={@node.open?}
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
          <li :for={{_, child} <- @node.children} class="flex flex-col">
            <.term id={@id} node={child} />
          </li>
        </ol>
        <div class="ml-[2ch]">
          <.text_items items={@node.expanded_after} />
        </div>
      </.collapsible>
    </div>
    """
  end

  attr(:node, TermNode, required: true)
  attr(:selectable_level, :integer, default: nil)
  attr(:level, :integer, default: 0)

  def static_term(assigns) do
    assigns =
      assigns
      |> assign(:has_children?, TermNode.has_children?(assigns.node))

    ~H"""
    <div class="font-code flex [&>div>button]:hidden hover:[&>div>button]:block">
      <div :if={@selectable_level == @level and is_atom(@node.key)} class="w-4">
        <button
          class="text-button-green-content hover:text-button-green-content-hover"
          phx-click="pin-assign"
          phx-value-key={@node.key}
        >
          <.icon name="icon-plus" class="h-4 w-4" />
        </button>
      </div>
      <%= if @has_children? do %>
        <.static_collapsible
          open={@node.open?}
          label_class="max-w-max"
          chevron_class="text-code-2 m-auto w-[2ch] h-[2ch]"
          phx-click="toggle_node"
          phx-value-id={@node.id}
        >
          <:label :let={open}>
            <%= if open do %>
              <.text_items items={@node.expanded_before} />
            <% else %>
              <.text_items items={@node.content} />
            <% end %>
          </:label>
          <ol class="m-0 ml-[2ch] block list-none p-0">
            <li :for={{_, child} <- @node.children} class="flex flex-col">
              <.static_term node={child} selectable_level={@selectable_level} level={@level + 1} />
            </li>
          </ol>
          <div class="ml-[2ch]">
            <.text_items items={@node.expanded_after} />
          </div>
        </.static_collapsible>
      <% else %>
        <div class="ml-[2ch]">
          <.text_items items={@node.content} />
        </div>
      <% end %>
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
end
