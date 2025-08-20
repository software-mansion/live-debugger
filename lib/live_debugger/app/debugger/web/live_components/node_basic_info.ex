defmodule LiveDebugger.App.Debugger.Web.LiveComponents.NodeBasicInfo do
  @moduledoc """
  Basic information about the node.
  """

  use LiveDebugger.App.Web, :live_component

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Debugger.Web.Components, as: DebuggerComponents
  alias LiveDebugger.App.Debugger.Structs.TreeNode
  alias LiveDebugger.App.Debugger.Queries.Node, as: NodeQueries
  alias LiveDebugger.App.Debugger.Queries.LvProcess, as: LvProcessQueries
  alias LiveDebugger.App.Utils.Parsers

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:node_id, assigns.node_id)
    |> assign(:lv_process, assigns.lv_process)
    |> assign_node_type()
    |> assign_async_node_module()
    |> assign_async_parent_lv_process()
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:node_id, :any, required: true)
  attr(:lv_process, :any, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="w-full p-6 shrink-0 flex flex-col gap-2 border-b border-default-border">
      <.async_result :let={node_module} assign={@node_module}>
        <:loading>
          <div class="w-full h-30 flex justify-center items-center"><.spinner size="sm" /></div>
        </:loading>
        <:failed>
          <.alert class="w-[15rem]">
            <p>Couldn't load basic information about the node.</p>
          </.alert>
        </:failed>
        <div class="w-full flex flex-col">
          <span class="font-medium">Type:</span>
          <span><%= @node_type %></span>
          <div class="w-full flex flex-col">
            <span class="font-medium">Module:</span>

            <div class="flex gap-2">
              <.tooltip
                id={@id <> "-current-node-module"}
                content={node_module}
                class="truncate max-w-[232px]"
              >
                <%= node_module %>
              </.tooltip>
              <.copy_button id="copy-button-module-name" value={node_module} />
            </div>
          </div>
        </div>
      </.async_result>
      <.async_result :let={parent_lv_process} assign={@parent_lv_process}>
        <div :if={parent_lv_process} class="w-full flex flex-col">
          <span class="font-medium">Parent LiveView Process</span>
          <DebuggerComponents.live_view_link
            lv_process={parent_lv_process}
            id="parent-live-view-link"
          />
        </div>
      </.async_result>
    </div>
    """
  end

  defp assign_node_type(socket) do
    node_type =
      socket.assigns.node_id
      |> TreeNode.type()
      |> case do
        :live_view -> "LiveView"
        :live_component -> "LiveComponent"
      end

    assign(socket, :node_type, node_type)
  end

  defp assign_async_node_module(socket) do
    node_id = socket.assigns.node_id
    pid = socket.assigns.lv_process.pid

    assign_async(socket, :node_module, fn ->
      case NodeQueries.get_module_from_id(node_id, pid) do
        {:ok, module} ->
          node_module = Parsers.module_to_string(module)
          {:ok, %{node_module: node_module}}

        :error ->
          {:error, "Failed to get node module"}
      end
    end)
  end

  defp assign_async_parent_lv_process(socket) do
    parent_pid = socket.assigns.lv_process.parent_pid

    case parent_pid do
      nil ->
        assign(socket, :parent_lv_process, AsyncResult.ok(nil))

      pid ->
        assign_async(socket, :parent_lv_process, fn ->
          {:ok, %{parent_lv_process: LvProcessQueries.get_lv_process_with_retries(pid)}}
        end)
    end
  end
end
