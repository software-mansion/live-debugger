defmodule LiveDebugger.Components.Tree do
  use LiveDebuggerWeb, :component

  import LiveDebugger.Components.Collapsible
  import LiveDebugger.Components.Tooltip

  alias LiveDebugger.Services.TreeNode

  attr(:tree, :any, required: true, doc: "The TreeNode struct to render")

  def tree(assigns) do
    assigns = assign(assigns, :tree, format_tree(assigns.tree))

    ~H"""
    <.tree_node node={@tree} padding={0} />
    """
  end

  attr(:node, :any, required: true)
  attr(:padding, :integer, default: 0)

  defp tree_node(assigns) do
    assigns = assign(assigns, :collapsible?, length(assigns.node.children) > 0)

    ~H"""
    <div style={"padding-left: #{@padding}rem;"} class="w-full">
      <.collapsible
        :if={@collapsible?}
        id={@node.id}
        style="padding-left: #{@padding}rem;"
        open={true}
        chevron_class="text-primary-500"
      >
        <:label>
          <.label node={@node} />
        </:label>
        <div class="flex flex-col" style="padding-left: #{@padding}rem;">
          <.tree_node :for={child <- @node.children} node={child} padding={@padding + 1} />
        </div>
      </.collapsible>
      <.label :if={not @collapsible?} node={@node} />
    </div>
    """
  end

  attr(:node, :any, required: true)

  defp label(assigns) do
    ~H"""
    <.tooltip class="hover:bg-primary-100 hover:p-1 rounded-lg">
      <div class="flex gap-1">
        <.icon name={@node.icon} />
        <.h5 no_margin={true}>{@node.label}</.h5>
      </div>
      <.tooltip_content side="bottom" align="start" class="bg-white">
        {@node.tooltip}
      </.tooltip_content>
    </.tooltip>
    """
  end

  defp format_tree(tree) do
    children = Enum.map(tree.children, &format_tree/1)

    case tree do
      %TreeNode.LiveView{} ->
        %{
          id: tree.id,
          label: short_name(tree.module),
          tooltip: Atom.to_string(tree.module),
          children: children,
          icon: "hero-tv"
        }

      %TreeNode.LiveComponent{} ->
        %{
          id: tree.id,
          label: "#{short_name(tree.module)} (#{tree.cid})",
          tooltip: Atom.to_string(tree.module),
          children: children,
          icon: "hero-cube"
        }
    end
  end

  defp short_name(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end
end
