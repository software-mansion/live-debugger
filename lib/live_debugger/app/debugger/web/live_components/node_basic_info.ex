defmodule LiveDebugger.App.Debugger.Web.LiveComponents.NodeBasicInfo do
  @moduledoc """
  Basic information about the node.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.App.Debugger.Structs.TreeNode
  alias LiveDebugger.App.Debugger.Queries.Node, as: NodeQueries
  alias LiveDebugger.App.Debugger.Web.LiveComponents.SendEventFullscreen
  alias LiveDebugger.App.Utils.Parsers

  alias LiveDebugger.App.Debugger.Web.Components.Pages

  @impl true
  def update(%{module_pulse?: pulse}, socket) do
    socket
    |> assign(:module_pulse?, pulse)
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:node_id, assigns.node_id)
    |> assign(:lv_process, assigns.lv_process)
    |> assign(:module_pulse?, false)
    |> assign_node_type()
    |> assign_async_node_module()
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:node_id, :any, required: true)
  attr(:lv_process, :any, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="w-full min-w-[20rem] h-max max-h-full overflow-y-auto p-4 shrink-0 flex flex-col border border-default-border bg-surface-0-bg rounded-sm"
    >
      <.async_result :let={node_module} assign={@node_module}>
        <:loading>
          <div class="w-full h-30 flex justify-center items-center"><.spinner size="sm" /></div>
        </:loading>
        <:failed>
          <.alert class="w-[15rem]">
            <p>Couldn't load basic information about the node.</p>
          </.alert>
        </:failed>
        <div class="flex flex-row gap-8 max-md_ct:flex-col max-md_ct:gap-2 md_ct:items-center p-3">
          <div class="min-w-0 flex flex-col gap-2 max-md_ct:border-b max-md_ct:border-default-border">
            <span class="font-medium">Module:</span>
            <div class="flex gap-2 min-w-0">
              <.tooltip id={@id <> "-current-node-module"} content={node_module} class="truncate">
                <%= node_module %>
              </.tooltip>
              <.copy_button id="copy-button-module-name" value={node_module} />
            </div>
            <.button
              class="shrink-0 md_ct:ml-auto md_ct:hidden mb-3"
              variant="secondary"
              size="sm"
              id="show-components-tree-button"
              phx-click={Pages.get_open_sidebar_js(:node_inspector)}
            >
              <.icon name="icon-component" class="w-4 h-4" /> Show Components Tree
            </.button>
          </div>
          <div class="shrink-0 flex flex-col gap-2">
            <span class="font-medium">Type:</span>
            <span><%= @node_type %></span>
          </div>

          <.button
            class="shrink-0 md_ct:ml-auto"
            variant="secondary"
            size="sm"
            id="send-event-button"
            disabled={not @lv_process.alive?}
            phx-click="open-send-event"
            phx-target={@myself}
          >
            <.icon name="icon-send" class="w-4 h-4" /> Send Event
          </.button>
        </div>
      </.async_result>
      <.live_component
        module={SendEventFullscreen}
        id="send-event-fullscreen"
        lv_process={@lv_process}
        node_id={@node_id}
      />
    </div>
    """
  end

  @impl true
  def handle_event("open-send-event", _, socket) do
    socket
    |> push_event("send-event-fullscreen-open", %{})
    |> noreply()
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
end
