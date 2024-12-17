defmodule LiveDebugger.Components.Tree do
  use LiveDebuggerWeb, :component

  import LiveDebugger.Components.Collapsible
  import LiveDebugger.Components.Tooltip

  alias LiveDebugger.Services.TreeNode

  @doc """
  Tree component to render tree of live view and it's live components.
  You need to pass TreeNode struct to render the tree.
  This component emits `select_node` event with 'selected_id` param when a node is clicked.
  """

  attr(:tree, :any, required: true, doc: "The TreeNode struct to render")
  attr(:event_target, :any, required: true, doc: "The target for the click event")
  attr(:selected_node_id, :string, default: nil, doc: "The id of the selected node")

  def tree(assigns) do
    assigns = assign(assigns, :tree, format_tree(assigns.tree))

    ~H"""
    <.tree_node
      node={@tree}
      event_target={@event_target}
      add_padding?={false}
      selected_node_id={@selected_node_id}
    />
    """
  end

  attr(:node, :any, required: true)
  attr(:event_target, :any, required: true)
  attr(:add_padding?, :boolean, default: true)
  attr(:selected_node_id, :string)

  defp tree_node(assigns) do
    assigns =
      assigns
      |> assign(:collapsible?, length(assigns.node.children) > 0)
      |> assign(:selected?, assigns.node.id == assigns.selected_node_id)

    ~H"""
    <div class="relative flex flex-row">
      <div :if={@add_padding?} class="absolute top-0 left-2 h-full border-l-2 border-primary-300">
      </div>
      <div class={[
        "w-full rounded-lg p-1",
        if(@selected?, do: "bg-primary-100"),
        if(@add_padding?, do: "ml-3")
      ]}>
        <.collapsible :if={@collapsible?} id={@node.id} open={true} chevron_class="text-primary-500">
          <:label>
            <.label selected?={@selected?} event_target={@event_target} node={@node} />
          </:label>
          <div class="flex flex-col">
            <.tree_node
              :for={child <- @node.children}
              selected_node_id={@selected_node_id}
              node={child}
              event_target={@event_target}
            />
          </div>
        </.collapsible>
        <.label
          :if={not @collapsible?}
          selected?={@selected?}
          event_target={@event_target}
          node={@node}
        />
      </div>
    </div>
    """
  end

  attr(:node, :any, required: true)
  attr(:event_target, :any, required: true)
  attr(:selected?, :boolean, default: false)

  defp label(assigns) do
    ~H"""
    <button phx-click="select_node" phx-value-selected_id={@node.id} phx-target={@event_target}>
      <.tooltip>
        <div class="flex gap-1 items-center">
          <.icon name={@node.icon} />
          <.h5 no_margin={true} class={if(@selected?, do: "text-primary-500")}>{@node.label}</.h5>
        </div>
        <.tooltip_content side="bottom" align="start" class="bg-white">
          {@node.tooltip}
        </.tooltip_content>
      </.tooltip>
    </button>
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
