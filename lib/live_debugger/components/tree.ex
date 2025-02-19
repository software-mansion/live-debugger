defmodule LiveDebugger.Components.Tree do
  @moduledoc """
  Tree component which show nested tree of live view and live components.
  """

  use LiveDebuggerWeb, :component

  alias LiveDebugger.Structs.TreeNode

  @max_node_number 20

  @doc """
  Tree component which show nested tree of live view and live components.
  You need to pass TreeNode struct to render the tree.
  This component emits `select_node` event with `node_id` param to the `event_target` when a node is clicked. `node_id` is parsed.
  To calculate `max_opened_node_level` it uses `max_nesting_level/2` function.
  """

  attr(:tree_node, :any, required: true, doc: "The TreeNode struct to render")
  attr(:title, :string, required: true, doc: "The title of the tree")
  attr(:event_target, :any, required: true, doc: "The target for the click event")
  attr(:selected_node_id, :string, required: true, doc: "The id of the selected node")
  attr(:class, :string, default: nil, doc: "CSS class")

  attr(:max_opened_node_level, :integer,
    required: true,
    doc: "The maximum level of the tree to be opened"
  )

  def tree(assigns) do
    ~H"""
    <div class={["w-full overflow-y-auto flex flex-col", @class]}>
      <div class="shrink-0 font-medium text-secondary-600 px-6 py-3"><%= @title %></div>
      <div class="w-full px-1 overflow-y-auto">
        <.tree_node
          tree_node={@tree_node}
          selected_node_id={@selected_node_id}
          event_target={@event_target}
          root?={true}
          max_opened_node_level={@max_opened_node_level}
          level={0}
        />
      </div>
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

  attr(:tree_node, :any, required: true)
  attr(:event_target, :any, required: true)
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
    <div class="relative flex max-w-full">
      <div class="w-full">
        <.collapsible
          :if={@collapsible?}
          id={"collapsible-" <> @tree_node.parsed_id}
          chevron_class="text-primary-900 h-5 w-5"
          open={@open}
          label_class="w-full rounded-md py-1 hover:bg-secondary-100"
          label_style={style_for_padding(@level, @collapsible?)}
        >
          <:label>
            <.label
              selected?={@selected?}
              event_target={@event_target}
              node={@tree_node}
              level={@level}
              collapsible?={true}
            />
          </:label>
          <div class="flex flex-col">
            <.tree_node
              :for={child <- @tree_node.children}
              tree_node={child}
              selected_node_id={@selected_node_id}
              event_target={@event_target}
              root?={false}
              max_opened_node_level={@max_opened_node_level}
              level={@level + 1}
            />
          </div>
        </.collapsible>
        <.label
          :if={not @collapsible?}
          selected?={@selected?}
          event_target={@event_target}
          node={@tree_node}
          level={@level}
          collapsible?={false}
        />
      </div>
    </div>
    """
  end

  attr(:node, :any, required: true)
  attr(:event_target, :any, required: true)
  attr(:level, :integer, required: true)
  attr(:collapsible?, :boolean, required: true)
  attr(:selected?, :boolean, required: true)
  attr(:class, :string, default: nil)

  defp label(assigns) do
    assigns =
      assign(assigns, :padding_style, style_for_padding(assigns.level, assigns.collapsible?))

    ~H"""
    <button
      phx-click="select_node"
      phx-value-node_id={@node.parsed_id}
      phx-target={@event_target}
      class={[
        "flex w-full rounded-md hover:bg-secondary-100",
        unless(@collapsible?, do: "p-1"),
        @class
      ]}
      style={unless(@collapsible?, do: @padding_style)}
    >
      <div class="flex w-full gap-0.5 items-center">
        <.icon name={@node.icon} class="text-primary-900 w-5 h-5 shrink-0" />
        <.tooltip
          id={"tree_node_" <> @node.parsed_id}
          content={@node.tooltip}
          class="w-full flex overflow-x-hidden"
        >
          <div class={[
            "truncate",
            if(@selected?, do: "font-medium")
          ]}>
            <%= @node.label %>
          </div>
        </.tooltip>
      </div>
    </button>
    """
  end

  defp style_for_padding(level, collapsible?) do
    padding = (level + 1) * 0.5 + if(collapsible?, do: 0, else: 1.5)

    "padding-left: #{padding}rem;"
  end

  defp format_tree_node(%TreeNode.LiveView{} = node) do
    %{
      id: TreeNode.id(node),
      parsed_id: TreeNode.display_id(node),
      label: short_name(node.module),
      tooltip: "#{Atom.to_string(node.module)}",
      children: node.children,
      icon: "icon-screen"
    }
  end

  defp format_tree_node(%TreeNode.LiveComponent{} = node) do
    %{
      id: TreeNode.id(node),
      parsed_id: TreeNode.display_id(node),
      label: "#{short_name(node.module)} (#{node.cid})",
      tooltip: "#{Atom.to_string(node.module)} (#{node.cid})",
      children: node.children,
      icon: "icon-component"
    }
  end

  defp short_name(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end

  defp count_by_level(node, level \\ 0, acc \\ %{}) do
    acc = Map.update(acc, level, 1, &(&1 + 1))

    Enum.reduce(node.children, acc, fn child, acc ->
      count_by_level(child, level + 1, acc)
    end)
  end
end
