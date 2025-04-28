defmodule LiveDebuggerWeb.Components.Tree do
  @moduledoc """
  Tree component which show nested tree of live view and live components.
  """

  use LiveDebuggerWeb, :component

  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Structs.TreeNode

  @max_node_number 20

  @doc """
  Tree component which show nested tree of live view and live components.
  You need to pass TreeNode struct to render the tree.
  This component emits `select_node` event with `node_id` param when a node is clicked. `node_id` is parsed.
  To calculate `max_opened_node_level` it uses `max_nesting_level/2` function.
  """

  attr(:id, :string, required: true, doc: "The id of the tree")
  attr(:tree_node, :any, required: true, doc: "The TreeNode struct to render")
  attr(:title, :string, required: true, doc: "The title of the tree")
  attr(:selected_node_id, :string, required: true, doc: "The id of the selected node")
  attr(:highlight?, :boolean, default: false, doc: "The highlight flag")
  attr(:class, :string, default: nil, doc: "CSS class")

  attr(:max_opened_node_level, :integer,
    required: true,
    doc: "The maximum level of the tree to be opened"
  )

  def tree(assigns) do
    ~H"""
    <div class={["min-h-20 px-1 overflow-y-auto overflow-x-hidden flex flex-col", @class]}>
      <div class="flex items-center justify-between">
        <div class="shrink-0 font-medium text-secondary-text px-6 py-3"><%= @title %></div>
        <%= if LiveDebugger.Feature.enabled?(:highlighting) do %>
          <.toggle_switch label="Highlight" checked={@highlight?} phx-click="toggle-highlight" />
        <% end %>
      </div>
      <.tree_node
        tree_id={@id}
        tree_node={@tree_node}
        selected_node_id={@selected_node_id}
        root?={true}
        max_opened_node_level={@max_opened_node_level}
        level={0}
      />
    </div>
    """
  end

  @doc """
  Calculates the maximum level to be opened in the tree.
  """
  @spec max_opened_node_level(root_node :: TreeNode.t(), max_nodes :: integer()) :: integer()
  def max_opened_node_level(root_node, max_nodes \\ @max_node_number) do
    node_count = count_by_level(root_node)

    node_count
    |> Enum.reduce_while({0, 0}, fn {level, count}, acc ->
      {_, parent_count} = acc
      new_count = count + parent_count

      if new_count > max_nodes do
        {:halt, {level - 1, new_count}}
      else
        {:cont, {level, new_count}}
      end
    end)
    |> elem(0)
  end

  attr(:tree_id, :string, required: true)
  attr(:parent_dom_id, :string, default: nil)
  attr(:tree_node, :any, required: true)
  attr(:selected_node_id, :string, default: nil)
  attr(:root?, :boolean, default: false)
  attr(:max_opened_node_level, :integer, default: 0)
  attr(:level, :integer, default: 0)

  defp tree_node(assigns) do
    assigns =
      assigns
      |> assign(:tree_node, format_tree_node(assigns.tree_node))
      |> assign(:collapsible?, length(assigns.tree_node.children) > 0)
      |> assign(:selected?, TreeNode.id(assigns.tree_node) == assigns.selected_node_id)
      |> assign(:open, assigns.level < assigns.max_opened_node_level)

    ~H"""
    <.collapsible
      :if={@collapsible?}
      id={"collapsible-#{@tree_node.parsed_id}-#{@tree_id}"}
      chevron_class="text-accent-icon h-5 w-5"
      open={@open}
      label_class="rounded-md py-1 hover:bg-surface-1-bg-hover"
      style={style_for_padding(@level, @collapsible?)}
    >
      <:label>
        <.label
          tree_id={@tree_id}
          selected?={@selected?}
          parent_dom_id={@parent_dom_id}
          node={@tree_node}
          level={@level}
          collapsible?={true}
        />
      </:label>
      <div class="flex flex-col">
        <.tree_node
          :for={child <- @tree_node.children}
          tree_id={@tree_id}
          parent_dom_id={if @tree_node[:dom_id], do: @tree_node.dom_id, else: @parent_dom_id}
          tree_node={child}
          selected_node_id={@selected_node_id}
          root?={false}
          max_opened_node_level={@max_opened_node_level}
          level={@level + 1}
        />
      </div>
    </.collapsible>
    <.label
      :if={not @collapsible?}
      tree_id={@tree_id}
      selected?={@selected?}
      parent_dom_id={@parent_dom_id}
      node={@tree_node}
      level={@level}
      collapsible?={false}
    />
    """
  end

  attr(:tree_id, :string, required: true)
  attr(:parent_dom_id, :string, required: true)
  attr(:node, :any, required: true)
  attr(:level, :integer, required: true)
  attr(:collapsible?, :boolean, required: true)
  attr(:selected?, :boolean, required: true)

  defp label(assigns) do
    assigns =
      assigns
      |> assign(:padding_style, style_for_padding(assigns.level, assigns.collapsible?))
      |> assign(:button_id, "tree-node-button-#{assigns.node.parsed_id}-#{assigns.tree_id}")

    ~H"""
    <span
      class={[
        "flex shrink grow items-center rounded-md hover:bg-surface-1-bg-hover",
        if(!@collapsible?, do: "p-1")
      ]}
      style={if(!@collapsible?, do: @padding_style)}
    >
      <button
        id={@button_id}
        phx-hook="Highlight"
        phx-click="select_node"
        phx-value-node_id={@node.parsed_id}
        phx-value-search-attribute={get_search_attribute(@node)}
        phx-value-search-value={get_search_value(@node, @parent_dom_id)}
        class="flex min-w-0 gap-0.5 items-center"
      >
        <.icon name={@node.icon} class="text-accent-icon w-5 h-5 shrink-0" />
        <.tooltip
          id={"tree-node-#{@node.parsed_id}-#{@tree_id}"}
          content={@node.tooltip}
          class="truncate"
        >
          <span class={["hover:underline", if(@selected?, do: "font-semibold")]}>
            <%= @node.label %>
          </span>
        </.tooltip>
      </button>
    </span>
    """
  end

  defp get_search_value(node, parent_id) do
    case node.id do
      %Phoenix.LiveComponent.CID{cid: cid} -> "c#{cid}-#{parent_id}"
      pid when is_pid(pid) -> node.dom_id
    end
  end

  defp get_search_attribute(node) do
    case node.id do
      %Phoenix.LiveComponent.CID{} -> "data-phx-id"
      pid when is_pid(pid) -> "id"
    end
  end

  defp style_for_padding(level, collapsible?) do
    padding = (level + 1) * 0.5 + if(collapsible?, do: 0, else: 1.5)

    "padding-left: #{padding}rem;"
  end

  defp format_tree_node(%TreeNode.LiveView{} = node) do
    %{
      dom_id: node.id,
      id: TreeNode.id(node),
      parsed_id: TreeNode.display_id(node),
      label: short_name(node.module),
      tooltip: Parsers.module_to_string(node.module),
      children: node.children,
      icon: "icon-screen"
    }
  end

  defp format_tree_node(%TreeNode.LiveComponent{} = node) do
    %{
      id: TreeNode.id(node),
      parsed_id: TreeNode.display_id(node),
      label: "#{short_name(node.module)} (#{node.cid})",
      tooltip: "#{Parsers.module_to_string(node.module)} (#{node.cid})",
      children: node.children,
      icon: "icon-component"
    }
  end

  defp short_name(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
  end

  defp count_by_level(node, level \\ 0, acc \\ %{}) do
    acc = Map.update(acc, level, 1, &(&1 + 1))

    Enum.reduce(node.children, acc, fn child, acc ->
      count_by_level(child, level + 1, acc)
    end)
  end
end
