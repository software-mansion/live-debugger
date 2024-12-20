defmodule LiveDebugger.LiveComponents.Sidebar do
  @moduledoc """
  Sidebar component which displays tree of live view and it's live components.
  """
  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Components.Tree
  alias LiveDebugger.Services.ChannelStateScraper
  alias PetalComponents.Alert

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
    |> assign_async_tree()
    |> ok()
  end

  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[20vw] min-w-60 min-h-screen bg-swm-blue flex flex-col gap-1 pt-4 p-2 pr-3 rounded-r-xl">
      <.h3 class="text-white">Live Debugger</.h3>
      <.separate_bar />
      <.basic_info pid={@pid} socket_id={@socket_id} />
      <.separate_bar />
      <.component_tree tree={@tree} selected_node_id={@selected_node_id} target={@myself} />
    </div>
    """
  end

  @impl true
  def handle_event("select_node", %{"selected_id" => selected_id}, socket) do
    {:noreply, assign(socket, selected_node_id: selected_id)}
  end

  defp basic_info(assigns) do
    ~H"""
    <.card class="p-4 flex flex-col gap-1 opacity-90 text-black">
      <div class="font-semibold text-swm-blue">Monitored socket:</div>
      <pre>{@socket_id}</pre>
      <div class="font-semibold text-swm-blue">Debugged PID:</div>
      <pre>{inspect(@pid)}</pre>
    </.card>
    """
  end

  defp component_tree(assigns) do
    ~H"""
    <.async_result :let={tree} assign={@tree}>
      <:loading>
        <div class="w-full flex justify-center mt-5"><.spinner class="text-white" /></div>
      </:loading>
      <:failed :let={_error}>
        <Alert.alert color="danger">Couldn't load a tree</Alert.alert>
      </:failed>
      <Tree.tree
        :if={tree}
        title="Components Tree"
        selected_node_id={@selected_node_id}
        tree_node={tree}
        event_target={@target}
      />
    </.async_result>
    """
  end

  defp separate_bar(assigns) do
    ~H"""
    <div class="border-b h-0 border-white my-4"></div>
    """
  end

  defp assign_async_tree(socket) do
    pid = socket.assigns.pid

    assign_async(socket, :tree, fn ->
      case ChannelStateScraper.build_tree(pid) do
        {:ok, tree} -> {:ok, %{tree: tree}}
        error -> error
      end
    end)
  end
end
