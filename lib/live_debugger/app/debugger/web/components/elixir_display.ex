defmodule LiveDebugger.App.Debugger.Web.Components.ElixirDisplay do
  @moduledoc """
  This module provides a component to display a tree of terms.
  Check `LiveDebugger.App.Utils.TermParser`.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Utils.TermNode
  alias LiveDebugger.App.Utils.TermNode.DisplayElement
  alias LiveDebugger.App.Utils.TermDiffer.Diff

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

  attr(:id, :string, default: "")
  attr(:node, TermNode, required: true)
  attr(:diff, Diff, default: nil)
  attr(:diff_class, :string, default: "")
  attr(:click_event, :string, default: "toggle_node")

  def static_term(assigns) do
    assigns =
      assigns
      |> assign(:has_children?, TermNode.has_children?(assigns.node))

    ~H"""
    <div class="font-code">
      <%= if @has_children? do %>
        <.static_collapsible
          open={@node.open?}
          label_class="max-w-max"
          chevron_class="text-code-2 m-auto w-[2ch] h-[2ch]"
          phx-click={@click_event}
          phx-value-id={@node.id}
        >
          <:label :let={open}>
            <%= if open do %>
              <.text_items id={@id <> @node.id <> "-expanded-before"} items={@node.expanded_before} />
            <% else %>
              <div class={content_diff_class(@diff, @diff_class)}>
                <.text_items id={@id <> @node.id <> "-content"} items={@node.content} />
              </div>
            <% end %>
          </:label>
          <ol class="m-0 ml-[2ch] block list-none p-0">
            <li
              :for={{key, child} <- @node.children}
              class={"flex flex-col #{child_diff_class(@diff, key, @diff_class)}"}
            >
              <.static_term
                id={@id}
                node={child}
                click_event={@click_event}
                diff={get_child_diff(@diff, key)}
                diff_class={@diff_class}
              />
            </li>
          </ol>
          <div class="ml-[2ch]">
            <.text_items id={@id <> @node.id <> "-expanded-after"} items={@node.expanded_after} />
          </div>
        </.static_collapsible>
      <% else %>
        <div class="ml-[2ch]">
          <.text_items id={@id <> @node.id} items={@node.content} />
        </div>
      <% end %>
    </div>
    """
  end

  attr(:id, :string, default: nil)
  attr(:items, :list, required: true)

  defp text_items(assigns) do
    ~H"""
    <div class="flex">
      <%= for {item, index} <- Enum.with_index(@items) do %>
        <span
          id={if(@id, do: @id <> "-#{index}")}
          phx-hook={if(@id, do: "DiffPulse")}
          data-pulse={item.pulse?}
          class={text_item_color_class(item)}
        >
          <pre data-text_item="true"><%= item.text %></pre>
        </span>
      <% end %>
    </div>
    """
  end

  defp text_item_color_class(%DisplayElement{color: color}) do
    if color, do: "#{color}", else: ""
  end

  defp content_diff_class(nil, _), do: ""
  defp content_diff_class(%Diff{type: :equal}, _), do: ""
  defp content_diff_class(%Diff{}, diff_class), do: diff_class

  defp child_diff_class(nil, _, _), do: ""

  defp child_diff_class(diff, key, diff_class) do
    if final_diff?(diff, key), do: diff_class, else: ""
  end

  defp get_child_diff(nil, _), do: nil
  defp get_child_diff(diff, key), do: if(not final_diff?(diff, key), do: diff.diff[key])

  defp final_diff?(%Diff{ins: ins, del: del, diff: diff}, key) do
    Map.has_key?(ins, key) or Map.has_key?(del, key) or
      (Map.has_key?(diff, key) && diff[key].type == :primitive)
  end
end
