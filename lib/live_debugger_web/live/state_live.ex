defmodule LiveDebuggerWeb.StateLive do
  @moduledoc """
  This nested live view displays the state of a LiveView.
  """

  use LiveDebuggerWeb, :live_view

  alias Phoenix.LiveView.AsyncResult

  alias LiveDebuggerWeb.Components.ElixirDisplay
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebuggerWeb.Helpers.StateHelper

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true)
  attr(:node_id, :string, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "node_id" => assigns.node_id,
      "parent_socket_id" => assigns.socket.id
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: @class}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    lv_process = session["lv_process"]
    parent_socket_id = session["parent_socket_id"]
    node_id = session["node_id"]

    if connected?(socket) do
      parent_socket_id
      |> PubSubUtils.node_changed_topic()
      |> PubSubUtils.subscribe!()

      lv_process.pid
      |> PubSubUtils.state_changed_topic(node_id)
      |> PubSubUtils.subscribe!()
    end

    socket
    |> assign(node_id: node_id)
    |> assign(lv_process: lv_process)
    |> assign_async_node_with_type()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 max-w-full flex flex-col gap-4">
      <.async_result :let={node} assign={@node}>
        <:loading>
          <div class="w-full flex items-center justify-center">
            <.spinner size="sm" />
          </div>
        </:loading>
        <:failed>
          <.alert class="w-full" variant="danger" with_icon heading="Error while fetching node state">
            Check logs for more
          </.alert>
        </:failed>

        <.assigns_section assigns={node.assigns} />
        <.fullscreen id="assigns-display-fullscreen" title="Assigns">
          <ElixirDisplay.term
            id="assigns-display-fullscreen-term"
            node={TermParser.term_to_display_tree(node.assigns)}
            level={1}
          />
        </.fullscreen>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_info({:state_changed, channel_state, _trace}, socket) do
    socket
    |> assign_async_node_with_type(channel_state)
    |> noreply()
  end

  @impl true
  def handle_info({:node_changed, new_node_id}, socket) do
    lv_process = socket.assigns.lv_process
    old_node_id = socket.assigns.node_id

    lv_process.pid
    |> PubSubUtils.state_changed_topic(old_node_id)
    |> PubSubUtils.unsubscribe()

    lv_process.pid
    |> PubSubUtils.state_changed_topic(new_node_id)
    |> PubSubUtils.subscribe!()

    socket
    |> assign(node_id: new_node_id)
    |> assign_async_node_with_type()
    |> noreply()
  end

  attr(:assigns, :list, required: true)

  defp assigns_section(assigns) do
    ~H"""
    <.section id="assigns" class="h-max overflow-y-hidden" title="Assigns">
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
    </.section>
    """
  end

  defp assign_async_node_with_type(socket, channel_state \\ nil)

  defp assign_async_node_with_type(
         %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket,
         channel_state
       )
       when not is_nil(node_id) do
    assign_async(socket, [:node, :node_type], fn ->
      with {:ok, channel_state} <- StateHelper.maybe_get_state(pid, channel_state),
           {:ok, node} <- ChannelService.get_node(channel_state, node_id),
           true <- not is_nil(node) do
        {:ok, %{node: node, node_type: TreeNode.type(node)}}
      else
        false -> {:error, :node_deleted}
        err -> err
      end
    end)
  end

  defp assign_async_node_with_type(socket, _channel_state) do
    socket
    |> assign(:node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
    |> assign(:node_type, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end
end
