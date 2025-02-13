defmodule LiveDebugger.LiveComponents.NodeDetails do
  @moduledoc false

  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Structs.TreeNode

  alias Phoenix.LiveView.AsyncResult

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(%{
      node_id: assigns.node_id,
      pid: assigns.pid,
      socket_id: assigns.socket_id
    })
    |> assign_async_node()
    |> ok()
  end

  attr(:node_id, :any, required: true)
  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.collapsible_section id="node-info" title="Details" class="border-b-2 border-primary">
        <.async_result :let={node} assign={@node}>
          <:loading>
            <div class="w-full flex items-center justify-center">
              <.spinner size="md" />
            </div>
          </:loading>
          <:failed>
            <.alert variant="danger" class="w-full">
              Failed to fetch node details
            </.alert>
          </:failed>
          <div class=" flex flex-col gap-1">
            <.info_row name="Type" value={node_type(node)} />
            <.info_row name={id_type(node)} value={TreeNode.display_id(node)} />
            <.info_row name="Module" value={inspect(node.module)} />
          </div>
        </.async_result>
      </.collapsible_section>
    </div>
    """
  end

  defp info_row(assigns) do
    ~H"""
    <div class="flex gap-1 overflow-x-hidden">
      <div class="font-bold w-20 text-primary">
        <%= @name %>
      </div>
      <div class="font-semibold break-all">
        <%= @value %>
      </div>
    </div>
    """
  end

  defp assign_async_node(%{assigns: %{node_id: nil}} = socket) do
    assign(socket, :node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  defp assign_async_node(%{assigns: %{node_id: node_id, pid: pid}} = socket) do
    assign_async(socket, [:node], fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
           {:ok, node} <- ChannelService.get_node(channel_state, node_id),
           true <- not is_nil(node) do
        {:ok, %{node: node}}
      else
        false -> {:error, :node_deleted}
        err -> err
      end
    end)
  end

  defp node_type(node) do
    case TreeNode.type(node) do
      :live_component -> "LiveComponent"
      :live_view -> "LiveView"
    end
  end

  defp id_type(node) do
    case TreeNode.type(node) do
      :live_component -> "CID"
      :live_view -> "PID"
    end
  end
end
