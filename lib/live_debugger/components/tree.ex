defmodule LiveDebugger.Components.Tree do
  use LiveDebuggerWeb, :component

  import LiveDebugger.Components.Collapsible
  import LiveDebugger.Components.Tooltip

  alias LiveDebugger.Services.TreeNode

  @doc """
  Tree component to recursively render tree of live view and its live components.
  You need to pass TreeNode struct to render the tree.
  This component emits `select_node` event with 'selected_id` param when a node is clicked.
  """

  attr(:tree_node, :any, required: true, doc: "The TreeNode struct to render")
  attr(:event_target, :any, required: true, doc: "The target for the click event")
  attr(:add_padding?, :boolean, default: false, doc: "Add padding to the tree node")
  attr(:selected_node_id, :string, default: nil, doc: "The id of the selected node")

  def tree(assigns) do
    assigns =
      assigns
      |> assign(:tree_node, format_tree_node(assigns.tree_node))
      |> assign(:collapsible?, length(assigns.tree_node.children) > 0)
      |> assign(:selected?, assigns.tree_node.id == assigns.selected_node_id)

    ~H"""
    <div class="relative flex flex-row min-w-max">
      <div :if={@add_padding?} class="absolute top-0 left-2 h-full border-l-2 border-primary-300">
      </div>
      <div class={[
        "w-full rounded-lg p-1",
        if(@selected?, do: "bg-primary-100"),
        if(@add_padding?, do: "ml-3")
      ]}>
        <.collapsible
          :if={@collapsible?}
          id={@tree_node.id}
          open={true}
          chevron_class="text-primary-500 mb-1"
        >
          <:label>
            <.label selected?={@selected?} event_target={@event_target} node={@tree_node} />
          </:label>
          <div class="flex flex-col">
            <.tree
              :for={child <- @tree_node.children}
              tree_node={child}
              selected_node_id={@selected_node_id}
              event_target={@event_target}
              add_padding?={true}
            />
          </div>
        </.collapsible>
        <.label
          :if={not @collapsible?}
          selected?={@selected?}
          event_target={@event_target}
          node={@tree_node}
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
          <.icon name={@node.icon} class="shrink-0" />
          <.h5 no_margin={true} class={["", if(@selected?, do: "text-primary-500")]}>
            {@node.label}
          </.h5>
        </div>
        <.tooltip_content side="bottom" align="start" class="bg-white">
          {@node.tooltip}
        </.tooltip_content>
      </.tooltip>
    </button>
    """
  end

  defp format_tree_node(node = %TreeNode.LiveView{}) do
    %{
      id: node.id,
      label: short_name(node.module),
      tooltip: "#{Atom.to_string(node.module)} (#{inspect(node.pid)})",
      children: node.children,
      icon: "hero-tv"
    }
  end

  defp format_tree_node(node = %TreeNode.LiveComponent{}) do
    %{
      id: node.id,
      label: "#{short_name(node.module)} (#{node.cid})",
      tooltip: "#{Atom.to_string(node.module)} (#{node.cid})",
      children: node.children,
      icon: "hero-cube"
    }
  end

  defp short_name(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end
end
