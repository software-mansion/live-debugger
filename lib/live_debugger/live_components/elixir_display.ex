defmodule LiveDebugger.LiveComponents.ElixirDisplay do
  @moduledoc """
  This module provides a LiveComponent to display a tree of terms.
  Check LiveDebugger.Utils.TermParser.
  """

  use LiveDebuggerWeb, :live_component

  @max_auto_expand_size 6

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:node, assigns.node)
    |> assign(:level, assigns.level)
    |> assign(:expanded?, auto_expand?(assigns.node, assigns.level))
    |> ok()
  end

  attr(:node, :any, required: true)
  attr(:level, :integer, required: true)
  attr(:expanded?, :boolean, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="font-mono text-sm text-gray-500">
      <div>
        <div
          class={"flex #{if has_children?(@node), do: "cursor-pointer"}"}
          phx-click={if has_children?(@node), do: "expand-click"}
          phx-target={@myself}
        >
          <div class="mr-0.5 inline-block w-[2ch] flex-shrink-0">
            <.icon
              :if={has_children?(@node) and @expanded?}
              name="hero-chevron-up-micro"
              class="w-4 h-4"
            />
            <.icon
              :if={has_children?(@node) and not @expanded?}
              name="hero-chevron-right-micro"
              class="w-4 h-4"
            />
          </div>
          <div>
            <%= if has_children?(@node) and @expanded? do %>
              <.text_items items={@node.expanded_before} />
            <% else %>
              <.text_items items={@node.content} />
            <% end %>
          </div>
        </div>
      </div>
      <div :if={has_children?(@node) and @expanded?}>
        <ol class="m-0 ml-[2ch] block list-none p-0">
          <%= for {child, index} <- Enum.with_index(@node.children) do %>
            <li class="flex flex-col">
              <.live_component
                id={@id <> "-#{index}"}
                module={__MODULE__}
                node={child}
                level={@level + 1}
              />
            </li>
          <% end %>
        </ol>
        <div class="ml-[2ch]">
          <.text_items items={@node.expanded_after} />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("expand-click", _params, socket) do
    socket
    |> assign(:expanded?, not socket.assigns.expanded?)
    |> noreply()
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
