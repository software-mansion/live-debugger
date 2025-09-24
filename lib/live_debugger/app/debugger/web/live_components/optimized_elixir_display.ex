defmodule LiveDebugger.App.Debugger.Web.LiveComponents.OptimizedElixirDisplay do
  @moduledoc """
  Optimized ElixirDisplay LiveComponent that can be used to display a tree of terms.
  It removes children of collapsed nodes from HTML, and adds them when the node is opened.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Utils.TermParser.TermNode

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:node, assigns.node)
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:node, TermNode, required: true)

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :send_event_fn, &send_event_fn(&1, assigns.myself))

    ~H"""
    <div id={@id}>
      <ElixirDisplay.term id={"#{@id}_term"} node={@node} send_event_fn={@send_event_fn} />
    </div>
    """
  end

  @impl true
  def handle_event("toggle_node", %{"id" => id}, socket) do
    node = update_node_children(socket.assigns.node, id)

    socket
    |> assign(:node, node)
    |> noreply()
  end

  defp send_event_fn(assigns, myself) do
    %{"phx-click" => "toggle_node", "phx-target" => myself, "phx-value-id" => assigns.node.id}
  end

  defp update_node_children(node, "root"), do: toggle_children_display(node)

  defp update_node_children(node, id) do
    ["root" | id_path] = id |> String.split(".")

    id_path = Enum.map(id_path, &String.to_integer(&1))

    recursively_update_node_children(node, id_path)
  end

  defp recursively_update_node_children(node, []) when is_struct(node, TermNode) do
    toggle_children_display(node)
  end

  defp recursively_update_node_children(node, [id | rest]) when is_struct(node, TermNode) do
    child_node =
      node.children
      |> Enum.at(id)
      |> recursively_update_node_children(rest)

    updated_children = List.replace_at(node.children, id, child_node)

    %TermNode{node | children: updated_children}
  end

  defp toggle_children_display(node) when is_struct(node, TermNode) do
    update_children =
      Enum.map(node.children, fn child -> %TermNode{child | display?: !child.display?} end)

    %TermNode{node | children: update_children}
  end
end
