defmodule LiveDebugger.LiveComponents.Sidebar do
  @moduledoc """
  Sidebar component which displays tree of live view and it's live components.
  """
  use LiveDebuggerWeb, :live_component

  import LiveDebugger.Components.Tree

  alias LiveDebugger.Services.ChannelStateScraper

  @impl true
  def mount(socket) do
    socket
    |> assign(selected_node_id: nil)
    |> ok()
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign_tree()
    |> maybe_assign_selected_node()
    |> ok()
  end

  attr(:pid, :any, required: true)

  def render(assigns) do
    ~H"""
    <div class="w-[20vw] min-w-56 h-screen p-2 border-r-2 border-primary-500 overflow-y-auto">
      <.h3 class="text-primary-500">Components Tree</.h3>
      <.tree
        :if={@tree}
        selected_node_id={@selected_node_id}
        tree_node={@tree}
        event_target={@myself}
      />
    </div>
    """
  end

  @impl true
  def handle_event("select_node", %{"selected_id" => selected_id}, socket) do
    {:noreply, assign(socket, selected_node_id: selected_id)}
  end

  defp assign_tree(socket) do
    case ChannelStateScraper.build_tree(socket.assigns.pid) do
      {:ok, tree} ->
        assign(socket, tree: tree)

      {:error, _} ->
        assign(socket, tree: nil)
    end
  end

  defp maybe_assign_selected_node(socket) do
    case socket.assigns.selected_node_id do
      nil -> assign(socket, selected_node_id: socket.assigns.tree.id)
      _ -> socket
    end
  end
end
