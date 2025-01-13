defmodule LiveDebugger.LiveComponents.Sidebar do
  @moduledoc """
  Sidebar component which displays tree of live view and it's live components.
  It changes path to `<base_url>/<node_id>` when a node is selected.
  """
  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Components.Tree
  alias LiveDebugger.Services.ChannelStateScraper

  require Logger

  @impl true
  def update(%{new_trace: trace}, socket) do
    existing_node_ids = socket.assigns.existing_node_ids
    trace_node_id = Trace.node_id(trace)

    cond do
      existing_node_ids.ok? and not MapSet.member?(existing_node_ids.result, trace_node_id) ->
        Logger.debug("New node detected #{inspect(trace_node_id)} refreshing the tree")
        updated_map_set = MapSet.put(existing_node_ids.result, trace_node_id)

        socket
        |> assign_async_tree()
        |> assign(:existing_node_ids, Map.put(existing_node_ids, :result, updated_map_set))

      match?(%{module: Phoenix.LiveView.Diff, function: :delete_component, arity: 2}, trace) ->
        Logger.debug("LiveComponent deleted #{inspect(trace_node_id)} refreshing the tree")

        updated_map_set = MapSet.delete(existing_node_ids.result, trace_node_id)

        socket
        |> assign_async_tree()
        |> assign(:existing_node_ids, Map.put(existing_node_ids, :result, updated_map_set))

      true ->
        socket
    end
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(%{
      pid: assigns.pid,
      socket_id: assigns.socket_id,
      node_id: assigns.node_id,
      base_url: assigns.base_url
    })
    |> assign_async_tree()
    |> assign_async_existing_node_ids()
    |> ok()
  end

  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)
  attr(:node_id, :any, required: true)
  attr(:base_url, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[20vw] min-w-60 min-h-max h-screen bg-swm-blue flex flex-col gap-1 pt-4 p-2 pr-3 rounded-r-xl">
      <.h3 class="text-white">Live Debugger</.h3>
      <.separate_bar />
      <.basic_info pid={@pid} socket_id={@socket_id} />
      <.separate_bar />
      <.component_tree tree={@tree} selected_node_id={@node_id} target={@myself} />
    </div>
    """
  end

  @impl true
  def handle_event("select_node", %{"node_id" => node_id}, socket) do
    socket
    |> push_patch(to: "#{socket.assigns.base_url}/#{node_id}")
    |> noreply()
  end

  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)

  defp basic_info(assigns) do
    ~H"""
    <.card class="p-4 flex flex-col gap-1 opacity-90 text-black">
      <%= for {text, value} <- [
        {"Monitored socket:", @socket_id},
        {"Debugged PID:", Parsers.pid_to_string(@pid)}
      ] do %>
        <div class="font-semibold text-swm-blue">{text}</div>
        <div>{value}</div>
      <% end %>
    </.card>
    """
  end

  attr(:tree, :any, required: true)
  attr(:target, :any, required: true)
  attr(:selected_node_id, :string, default: nil)

  defp component_tree(assigns) do
    ~H"""
    <.async_result :let={tree} assign={@tree}>
      <:loading>
        <div class="w-full flex justify-center mt-5"><.spinner class="text-white" /></div>
      </:loading>
      <:failed :let={_error}>
        <.alert color="danger">Couldn't load a tree</.alert>
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

  defp assign_async_existing_node_ids(socket) do
    pid = socket.assigns.pid

    assign_async(socket, :existing_node_ids, fn ->
      case ChannelStateScraper.all_node_ids(pid) do
        {:ok, node_ids} ->
          {:ok, %{existing_node_ids: MapSet.new(node_ids)}}

        {:error, error} ->
          Logger.error("Failed to get existing node ids: #{inspect(error)}")
          {:error, error}
      end
    end)
  end

  defp assign_async_tree(socket) do
    pid = socket.assigns.pid

    assign_async(socket, :tree, fn ->
      case ChannelStateScraper.build_tree(pid) do
        {:ok, tree} ->
          {:ok, %{tree: tree}}

        {:error, error} ->
          Logger.error("Failed to build tree: #{inspect(error)}")
          {:error, error}
      end
    end)
  end
end
