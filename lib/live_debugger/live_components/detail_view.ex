defmodule LiveDebugger.LiveComponents.DetailView do
  @moduledoc """
  This module is responsible for rendering the detail view of the TreeNode.
  It requires the node_id to be passed as an assign or in update function to render the detail view.
  """

  alias LiveDebugger.Services.TreeNode
  alias Phoenix.LiveView.AsyncResult
  alias PetalComponents.Alert
  alias LiveDebugger.Services.ChannelStateScraper

  use LiveDebuggerWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(%{
      node_id: assigns.node_id,
      pid: assigns.pid,
      socket_id: assigns.socket_id
    })
    |> assign_async_node_with_type()
    |> ok()
  end

  attr(:node_id, :any, required: true)
  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col w-full h-screen max-h-screen gap-4 p-2 overflow-x-hidden overflow-y-auto md:overflow-y-hidden">
      <.async_result :let={node} assign={@node}>
        <:loading>
          <div class="w-full flex items-center justify-center">
            <.spinner size="md" />
          </div>
        </:loading>
        <:failed :let={reason}>
          <Alert.alert color="danger">
            Failed to fetch node details: {inspect(reason)}
          </Alert.alert>
        </:failed>
        <div class="grid grid-cols-1 gap-2 md:grid-cols-2 md:h-full">
          <div class="flex flex-col gap-4 max">
            <.info_card node={node} node_type={@node_type.result} />
            <.assigns_card assigns={node.assigns} />
          </div>
          <.events_card pid={@pid} socket_id={@socket_id} />
        </div>
      </.async_result>
    </div>
    """
  end

  attr(:node, :any, required: true)
  attr(:node_type, :atom, required: true)

  defp info_card(assigns) do
    ~H"""
    <.basic_card title={title(@node_type)}>
      <div class=" flex flex-col gap-1">
        <.info_row name={id_type(@node_type)} value={TreeNode.parsed_id(@node)} />
        <.info_row name="Module" value={inspect(@node.module)} />
        <.info_row name="HTML ID" value={@node.id} />
      </div>
    </.basic_card>
    """
  end

  attr(:name, :string, required: true)
  attr(:value, :any, required: true)

  defp info_row(assigns) do
    ~H"""
    <div class="flex gap-1 overflow-x-hidden">
      <div class="font-bold text-swm-blue">
        {@name}
      </div>
      <div class="break-all">
        {@value}
      </div>
    </div>
    """
  end

  defp title(:live_component), do: "Live Component"
  defp title(:live_view), do: "Live View"

  defp id_type(:live_component), do: "CID"
  defp id_type(:live_view), do: "PID"

  attr(:assigns, :list, required: true)

  defp assigns_card(assigns) do
    ~H"""
    <.basic_card title="Assigns">
      <div class="w-full whitespace-pre-wrap break-words overflow-y-auto">
        {inspect(@assigns, pretty: true)}
      </div>
    </.basic_card>
    """
  end

  defp events_card(assigns) do
    ~H"""
    <.basic_card title="Events" class="h-full">
      <.live_component
        id="event-list"
        module={LiveDebugger.LiveComponents.EventsList}
        debugged_node_id={@pid}
        socket_id={@socket_id}
      />
    </.basic_card>
    """
  end

  attr(:title, :string, required: true)
  attr(:class, :string, default: "")

  slot(:inner_block)

  defp basic_card(assigns) do
    ~H"""
    <div class={[
      "flex flex-col gap-4 p-4 bg-swm-blue text-white rounded-xl shadow-xl",
      @class
    ]}>
      <.h3 class="text-white">{@title}</.h3>
      <div class="flex h-full overflow-y-auto overflow-x-hidden rounded-md bg-white opacity-90 text-black p-2">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp assign_async_node_with_type(%{assigns: %{node_id: node_id, pid: pid}} = socket)
       when not is_nil(node_id) do
    assign_async(socket, [:node, :node_type], fn ->
      with {:ok, node} <- ChannelStateScraper.get_node_from_pid(pid, node_id) do
        {:ok, %{node: node, node_type: TreeNode.type(node)}}
      end
    end)
  end

  defp assign_async_node_with_type(socket) do
    socket
    |> assign(:node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
    |> assign(:node_type, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end
end
