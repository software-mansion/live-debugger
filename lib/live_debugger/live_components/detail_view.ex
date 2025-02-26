defmodule LiveDebugger.LiveComponents.DetailView do
  @moduledoc """
  This module is responsible for rendering the detail view of the TreeNode.
  """

  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Structs.TreeNode
  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Components.ElixirDisplay

  @impl true
  def update(%{new_trace: _new_trace}, socket) do
    socket
    |> assign_async_node_with_type()
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(%{
      node_id: assigns.node_id || assigns.pid,
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
    <div class="flex flex-col flex-1 h-full overflow-auto">
      <.async_result :let={node} assign={@node}>
        <:loading>
          <div class="w-full flex items-center justify-center">
            <.spinner size="md" />
          </div>
        </:loading>
        <:failed :let={reason}>
          <.alert variant="danger">
            Failed to fetch node details: <%= inspect(reason) %>
          </.alert>
        </:failed>
        <div class="p-8 flex flex-col gap-4">
          <.info_section node={node} node_type={@node_type.result} socket_id={@socket_id} />
          <.assigns_section assigns={node.assigns} />
          <.fullscreen id="assigns-display-fullscreen" title="Assigns">
            <ElixirDisplay.term
              id="assigns-display-fullscreen-term"
              node={TermParser.term_to_display_tree(node.assigns)}
              level={1}
            />
          </.fullscreen>
          <.live_component
            id="trace-list"
            module={LiveDebugger.LiveComponents.TracesList}
            debugged_node_id={@node_id}
            socket_id={@socket_id}
          />
        </div>
      </.async_result>
    </div>
    """
  end

  attr(:node, :any, required: true)
  attr(:node_type, :atom, required: true)
  attr(:socket_id, :string, default: "")

  defp info_section(assigns) do
    ~H"""
    <div id="info">
      <.nested_badge :if={@node_type == :live_view and LiveDebugger.Utils.nested?(@socket_id)} />
      <div class="text-2xl grid grid-cols-2">
        <div>
          {inspect(@node.module)}
        </div>
        <div class="text-right">
          {id_type(@node_type)} {TreeNode.display_id(@node)}
        </div>
      </div>
    </div>
    """
  end

  defp title(:live_component), do: "LiveComponent"
  defp title(:live_view), do: "LiveView"

  defp id_type(:live_component), do: "CID"
  defp id_type(:live_view), do: "PID"

  attr(:assigns, :list, required: true)

  defp assigns_section(assigns) do
    ~H"""
    <.collapsible_section id="assigns" class="h-max overflow-y-hidden" title="Assigns">
      <:right_panel>
        <.fullscreen_button id="assigns-display-fullscreen" />
      </:right_panel>
      <div class="relative w-full h-max max-h-full p-4 overflow-y-auto">
        <ElixirDisplay.term
          id="assigns-display"
          node={TermParser.term_to_display_tree(@assigns)}
          level={1}
        />
      </div>
    </.collapsible_section>
    """
  end

  defp assign_async_node_with_type(%{assigns: %{node_id: node_id, pid: pid}} = socket)
       when not is_nil(node_id) do
    assign_async(socket, [:node, :node_type], fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
           {:ok, node} <- ChannelService.get_node(channel_state, node_id),
           true <- not is_nil(node) do
        {:ok, %{node: node, node_type: TreeNode.type(node)}}
      else
        false -> {:error, :node_deleted}
        err -> err
      end
    end)
  end

  defp assign_async_node_with_type(socket) do
    socket
    |> assign(:node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
    |> assign(:node_type, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end
end
