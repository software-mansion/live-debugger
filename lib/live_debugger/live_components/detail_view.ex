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
    |> assign(assigns)
    |> assign_async_node()
    |> ok()
  end

  attr(:node_id, :any, required: true)
  attr(:pid, :any, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col w-full h-screen gap-4 p-4">
      <.async_result :let={node} assign={@node}>
        <:loading>
          <div class="w-full flex items-center justify-center">
            <.spinner size="md" />
          </div>
        </:loading>
        <:failed :let={node_reason}>
          <Alert.alert type="error">
            Failed to fetch node details: {inspect(node_reason)}
          </Alert.alert>
        </:failed>
        <.detail_view node={node} />
      </.async_result>
    </div>
    """
  end

  attr(:node, :map, required: true)

  defp detail_view(assigns) do
    ~H"""
    <div class="flex gap-4 w-full h-full">
      <div class="flex flex-col gap-4 basis-1/2">
        <.basic_info node={@node} />
        <.assigns_table assigns_list={@node.assigns} />
      </div>
      <.events />
    </div>
    """
  end

  attr(:node, :any, required: true)

  defp basic_info(assigns) do
    assigns = assign(assigns, :type, TreeNode.type(assigns.node))

    ~H"""
    <.segment_card title={title(@type)}>
      <div class="flex flex-col gap-1">
        <.info_row name={id_type(@type)} value={TreeNode.parsed_id(@node)} />
        <.info_row name="Module" value={inspect(@node.module)} />
        <.info_row name="HTML ID" value={@node.id} />
      </div>
    </.segment_card>
    """
  end

  attr(:name, :string, required: true)
  attr(:value, :any, required: true)

  defp info_row(assigns) do
    ~H"""
    <div class="w-full flex gap-1">
      <div class="font-bold w-20">
        {@name}
      </div>
      <div>
        {@value}
      </div>
    </div>
    """
  end

  defp title(:live_component), do: "Live Component"
  defp title(:live_view), do: "Live View"

  defp id_type(:live_component), do: "CID"
  defp id_type(:live_view), do: "PID"

  attr(:assigns_list, :list, required: true)

  defp assigns_table(assigns) do
    ~H"""
    <.segment_card title="Assigns">
      <div class="grid grid-cols-2 max-w-max gap-1">
        <%= for {key, value} <- @assigns_list do %>
          <div class="font-bold">{key}</div>
          <div>{inspect(value)}</div>
        <% end %>
      </div>
    </.segment_card>
    """
  end

  defp events(assigns) do
    ~H"""
    <.segment_card title="Events" class="basis-1/2" />
    """
  end

  attr(:title, :string, required: true)
  attr(:class, :string, default: "")

  slot(:inner_block)

  defp segment_card(assigns) do
    ~H"""
    <.card class={["flex flex-col gap-4 p-4 w-full bg-swm-blue text-white", @class]} variant="outline">
      <.h3 class="text-white">{@title}</.h3>
      <div class="w-full rounded-md bg-white opacity-90 text-black p-2">
        {render_slot(@inner_block)}
      </div>
    </.card>
    """
  end

  defp assign_async_node(%{assigns: %{node_id: node_id, pid: pid}} = socket)
       when not is_nil(node_id) do
    assign_async(socket, :node, fn ->
      with {:ok, node} <- ChannelStateScraper.get_node_from_pid(pid, node_id) do
        {:ok, %{node: node}}
      end
    end)
  end

  defp assign_async_node(socket) do
    assign(socket, :node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end
end
