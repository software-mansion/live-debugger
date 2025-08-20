defmodule LiveDebugger.App.Debugger.ComponentsTree.Web.Components do
  @moduledoc """
  UI components used in the Components Tree
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Structs.TreeNode
  alias LiveDebugger.App.Utils.Parsers

  @doc """
  Renders a TreeNode component with its children recursively.

  ## Examples

      <.ComponentsTree.Web.Components.tree_node
        id="tree-id"
        tree_node={@tree}
        selected_node_id={@selected_node_id}
        max_opened_node_level={2}
      />

  """
  attr(:id, :string, required: true)
  attr(:tree_node, TreeNode, required: true, doc: "TreeNode struct")
  attr(:selected_node_id, :string, required: true)

  attr(:max_opened_node_level, :integer,
    required: true,
    doc: "Maximum level of nesting to be opened by default."
  )

  # These attributes are used only for the recursive calls
  attr(:root?, :boolean, default: true, doc: "Indicates if the node is a root node.")

  attr(:level, :integer,
    default: 0,
    doc: "The level of the node in the tree. Used for indentation and recursive rendering."
  )

  def tree_node(assigns) do
    parsed_node_id = TreeNode.parse_id(assigns.tree_node)

    assigns =
      assigns
      |> assign(:parsed_node_id, parsed_node_id)
      |> assign(:label_id, "tree-node-#{parsed_node_id}-#{assigns.id}")
      |> assign(:collapsible?, length(assigns.tree_node.children) > 0)
      |> assign(:selected?, assigns.tree_node.id == assigns.selected_node_id)
      |> assign(:open, assigns.level < assigns.max_opened_node_level)

    ~H"""
    <.collapsible
      :if={@collapsible?}
      id={"collapsible-#{@id}-#{@parsed_node_id}"}
      chevron_class="text-accent-icon h-5 w-5"
      open={@open}
      label_class="rounded-md py-1 hover:bg-surface-1-bg-hover"
      style={style_for_padding(@level, @collapsible?)}
    >
      <:label>
        <.label
          id={@label_id}
          tree_node={@tree_node}
          parsed_node_id={@parsed_node_id}
          selected?={@selected?}
          level={@level}
          collapsible?={true}
        />
      </:label>
      <div class="flex flex-col">
        <.tree_node
          :for={child <- @tree_node.children}
          id={@id}
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
      id={@label_id}
      tree_node={@tree_node}
      parsed_node_id={@parsed_node_id}
      selected?={@selected?}
      level={@level}
      collapsible?={false}
    />
    """
  end

  attr(:id, :string, required: true)
  attr(:tree_node, TreeNode, required: true)
  attr(:parsed_node_id, :string, required: true)
  attr(:level, :integer, required: true)
  attr(:collapsible?, :boolean, required: true)
  attr(:selected?, :boolean, required: true)

  defp label(assigns) do
    assigns =
      assigns
      |> assign(:padding_style, style_for_padding(assigns.level, assigns.collapsible?))
      |> assign(:button_id, "button-#{assigns.id}")
      |> assign(:icon, node_icon(assigns.tree_node))
      |> assign(:tooltip_content, node_tooltip(assigns.tree_node))
      |> assign(:label, node_label(assigns.tree_node))

    ~H"""
    <span
      id={@id}
      phx-hook="Highlight"
      phx-value-search-attribute={@tree_node.dom_id.attribute}
      phx-value-search-value={@tree_node.dom_id.value}
      phx-value-module={@tree_node.module}
      phx-value-type={@tree_node.type}
      phx-value-id={TreeNode.parse_id(@tree_node)}
      class={[
        "flex shrink grow items-center rounded-md hover:bg-surface-1-bg-hover",
        if(!@collapsible?, do: "p-1")
      ]}
      style={if(!@collapsible?, do: @padding_style)}
    >
      <button
        id={@button_id}
        phx-click="select_node"
        phx-value-node-id={@parsed_node_id}
        phx-value-search-attribute={@tree_node.dom_id.attribute}
        phx-value-search-value={@tree_node.dom_id.value}
        phx-value-module={@tree_node.module}
        phx-value-type={@tree_node.type}
        phx-value-id={TreeNode.parse_id(@tree_node)}
        class="flex min-w-0 gap-1 items-center"
      >
        <.icon name={@icon} class="text-accent-icon w-4 h-4 shrink-0" />
        <.tooltip id={@id <> "-tooltip"} content={@tooltip_content} class="truncate">
          <span class={["hover:underline", if(@selected?, do: "font-semibold")]}>
            <%= @label %>
          </span>
        </.tooltip>
      </button>
    </span>
    """
  end

  defp style_for_padding(level, collapsible?) do
    padding = (level + 1) * 0.5 + if(collapsible?, do: 0, else: 1.5)

    "padding-left: #{padding}rem;"
  end

  defp node_icon(%TreeNode{type: :live_view}), do: "icon-liveview"
  defp node_icon(%TreeNode{type: :live_component}), do: "icon-component"

  defp node_tooltip(%TreeNode{type: :live_view} = node) do
    Parsers.module_to_string(node.module)
  end

  defp node_tooltip(%TreeNode{type: :live_component} = node) do
    "#{Parsers.module_to_string(node.module)} (#{Parsers.cid_to_string(node.id)})"
  end

  defp node_label(%TreeNode{type: :live_view} = node) do
    Parsers.module_to_string(node.module)
  end

  defp node_label(%TreeNode{type: :live_component} = node) do
    "#{short_name(node.module)} (#{Parsers.cid_to_string(node.id)})"
  end

  defp short_name(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
