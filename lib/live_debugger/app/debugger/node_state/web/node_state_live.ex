defmodule LiveDebugger.App.Debugger.NodeState.Web.NodeStateLive do
  @moduledoc """
  This LiveView displays the state of a particular node (`LiveView` or `LiveComponent`).
  It is meant to be used as a composable nested LiveView in the Debugger page.
  """

  use LiveDebugger.App.Web, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Debugger.NodeState.Web.Components, as: NodeStateComponents
  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged
  alias LiveDebugger.Services.CallbackTracer.Events.StreamUpdated

  @doc """
  Renders the `NodeStateLive` as a nested LiveView component.

  `id` - dom id
  `socket` - parent LiveView socket
  `lv_process` - currently debugged LiveView process
  `params` - query parameters of the page.
  """

  attr(:id, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:node_id, :any, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "node_id" => assigns.node_id,
      "parent_pid" => self()
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
    parent_pid = session["parent_pid"]
    node_id = session["node_id"]

    if connected?(socket) do
      Bus.receive_events!(parent_pid)
      Bus.receive_states!(lv_process.pid)
    end

    socket
    |> assign(:lv_process, lv_process)
    |> assign(:node_id, node_id)
    |> assign_async_node_assigns()
    |> assign_async_node_streams()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 max-w-full flex flex-col gap-4">
      <.async_result :let={node_assigns} assign={@node_assigns}>
        <:loading>
          <NodeStateComponents.loading />
        </:loading>
        <:failed>
          <NodeStateComponents.failed />
        </:failed>

        <NodeStateComponents.assigns_section
          assigns={node_assigns}
          fullscreen_id="assigns-display-fullscreen"
        />
      </.async_result>

      <.async_result :let={streams_state} assign={@streams_state}>
        <:loading>
          <NodeStateComponents.loading />
        </:loading>
        <:failed>
          <NodeStateComponents.failed />
        </:failed>
        <NodeStateComponents.streams_section streams_state={streams_state} />
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_info(%NodeIdParamChanged{node_id: node_id}, socket) do
    socket
    |> assign(:node_id, node_id)
    |> assign_async_node_assigns()
    |> noreply()
  end

  def handle_info(%StateChanged{}, socket) do
    socket
    |> assign_async_node_assigns()
    |> noreply()
  end

  def handle_info(%StreamUpdated{streams: streams}, socket) do
    socket
    |> assign_async_node_streams(streams)
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp assign_async_node_assigns(
         %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket
       )
       when not is_nil(node_id) do
    assign_async(socket, :node_assigns, fn ->
      NodeStateQueries.fetch_node_assigns(pid, node_id)
    end)
  end

  defp assign_async_node_assigns(socket) do
    assign(socket, :node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  defp assign_async_node_streams(
         %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket
       )
       when not is_nil(node_id) do
    assign_async(socket, :streams_state, fn ->
      NodeStateQueries.fetch_node_streams(pid)
    end)
  end

  defp assign_async_node_streams(socket) do
    assign(socket, :streams, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  defp assign_async_node_streams(
         %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket,
         updated_streams
       )
       when not is_nil(node_id) do
    case Map.get(socket.assigns, :streams_state, nil) do
      nil ->
        assign_async_node_streams(socket)

      current_stream_state ->
        assign_async(socket, :streams_state, fn ->
          NodeStateQueries.update_node_streams(pid, updated_streams, current_stream_state)
        end)
    end
  end
end
