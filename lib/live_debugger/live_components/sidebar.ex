defmodule LiveDebugger.LiveComponents.Sidebar do
  @moduledoc """
  Sidebar component which displays tree of live view and it's live components.
  """
  use LiveDebuggerWeb, :live_component

  import LiveDebugger.Components.Tree

  alias LiveDebugger.Services.ChannelStateScraper

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign_tree()
    |> ok()
  end

  attr(:pid, :any, required: true)

  def render(assigns) do
    ~H"""
    <div class="min-w-max h-screen p-2 border-r-2 border-primary-500 ">
      <.h4 class="text-primary-500">LiveView Tree</.h4>
      <.tree :if={@tree} tree={@tree} />
    </div>
    """
  end

  defp assign_tree(socket) do
    case ChannelStateScraper.build_tree(socket.assigns.pid) do
      {:ok, tree} ->
        assign(socket, tree: tree)

      {:error, _} ->
        assign(socket, tree: nil)
    end
  end
end
