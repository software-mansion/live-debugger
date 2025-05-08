defmodule LiveDebuggerWeb.StateLive do
  @moduledoc """
  This nested live view displays the state of a LiveView.
  """

  use LiveDebuggerWeb, :live_view

  alias LiveDebugger.GenServers.StateServer
  alias Phoenix.LiveView.AsyncResult

  alias LiveDebuggerWeb.Components.ElixirDisplay
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.GenServers.StateServer

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

      PubSubUtils.state_changed_topic(
        lv_process.socket_id,
        lv_process.transport_pid,
        node_id
      )
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

        <.info_section node={node} node_type={@node_type.result} nested?={@lv_process.nested?} />
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
  def handle_info({:state_changed, channel_state}, socket) do
    socket
    |> assign_async_node_with_type(channel_state)
    |> noreply()
  end

  @impl true
  def handle_info({:updated_trace, _trace}, socket) do
    socket
    |> noreply()
  end

  @impl true
  def handle_info({:node_changed, node_id}, socket) do
    socket
    |> assign(node_id: node_id)
    |> assign_async_node_with_type()
    |> noreply()
  end

  attr(:node, :any, required: true)
  attr(:node_type, :atom, required: true)
  attr(:nested?, :boolean, default: false)

  defp info_section(assigns) do
    ~H"""
    <.section id="info" title={title(@node_type)}>
      <:right_panel>
        <.badge :if={@node_type == :live_view and @nested?} text="Nested" icon="icon-nested" />
      </:right_panel>
      <div class="p-4 flex flex-col gap-1">
        <.info_row name="Module" value={Parsers.module_to_string(@node.module)} />
        <.info_row name={id_type(@node_type)} value={TreeNode.display_id(@node)} />
      </div>
    </.section>
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
      with {:ok, channel_state} <- maybe_get_state(pid, channel_state),
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

  defp maybe_get_state(pid, channel_state) do
    if is_nil(channel_state) do
      StateServer.get(pid)
    else
      {:ok, channel_state}
    end
  end

  defp title(:live_component), do: "LiveComponent"
  defp title(:live_view), do: "LiveView"

  defp id_type(:live_component), do: "CID"
  defp id_type(:live_view), do: "PID"
end
