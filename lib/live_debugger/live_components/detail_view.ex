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
      node_id: assigns.node_id || assigns.lv_process.pid,
      lv_process: assigns.lv_process
    })
    |> assign_async_node_with_type()
    |> ok()
  end

  attr(:node_id, :any, required: true)
  attr(:lv_process, :any, required: true)

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
        <:failed>
          <.alert variant="danger" with_icon heading="Failed to fetch node details">
            Check logs for more
          </.alert>
        </:failed>
        <div class="overflow-auto grow p-8 items-center justify-start lg:items-start lg:justify-center flex flex-col lg:flex-row gap-4 lg:gap-8">
          <div class="w-full lg:w-1/2 flex flex-col gap-4 lg:items-end">
            <.info_section node={node} node_type={@node_type.result} nested?={@lv_process.nested?} />
            <.assigns_section assigns={node.assigns} />
            <.fullscreen id="assigns-display-fullscreen" title="Assigns">
              <ElixirDisplay.term
                id="assigns-display-fullscreen-term"
                node={TermParser.term_to_display_tree(node.assigns)}
                level={1}
              />
            </.fullscreen>
          </div>
          <div class="w-full lg:w-1/2">
            <.live_component
              id="trace-list"
              module={LiveDebugger.LiveComponents.TracesList}
              debugged_node_id={@node_id}
              socket_id={@lv_process.socket_id}
            />
          </div>
        </div>
      </.async_result>
    </div>
    """
  end

  attr(:node, :any, required: true)
  attr(:node_type, :atom, required: true)
  attr(:nested?, :boolean, default: false)

  defp info_section(assigns) do
    ~H"""
    <.collapsible_section id="info" title={title(@node_type)}>
      <:right_panel>
        <.badge :if={@node_type == :live_view and @nested?} text="Nested" icon="icon-nested" />
      </:right_panel>
      <div class="p-4 flex flex-col gap-1">
        <.info_row name="Module" value={inspect(@node.module)} />
        <.info_row name={id_type(@node_type)} value={TreeNode.display_id(@node)} />
      </div>
    </.collapsible_section>
    """
  end

  attr(:name, :string, required: true)
  attr(:value, :any, required: true)

  defp info_row(assigns) do
    ~H"""
    <div class="flex gap-1 overflow-x-hidden">
      <div class="font-medium">
        <%= @name %>
      </div>
      <div class="font-normal break-all">
        <%= @value %>
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

  defp assign_async_node_with_type(
         %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket
       )
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
