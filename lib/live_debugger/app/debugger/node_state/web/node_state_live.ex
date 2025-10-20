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

  alias LiveDebugger.App.Debugger.NodeState.Web.AssignsSearch

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged
  alias LiveDebugger.Utils.Memory

  @assigns_size_events [:assigns_size_1, :assigns_size_2]

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
    |> assign(:assigns_search_phrase, "")
    |> assign(:node_assigns, AsyncResult.loading())
    |> assign(:assigns_sizes, AsyncResult.loading())
    |> assign_async_node_assigns()
    |> AssignsSearch.init()
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
          assigns_sizes={@assigns_sizes}
          assigns_search_phrase={@assigns_search_phrase}
        />
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_info(%NodeIdParamChanged{node_id: node_id}, socket) do
    socket
    |> assign(:node_id, node_id)
    |> assign(:assigns_sizes, AsyncResult.loading())
    |> assign(:node_assigns, AsyncResult.loading())
    |> assign_async_node_assigns()
    |> noreply()
  end

  def handle_info(%StateChanged{}, socket) do
    socket
    |> assign_async_node_assigns()
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_async(:node_assigns, {:ok, node_assigns}, socket) do
    socket
    |> assign(:node_assigns, AsyncResult.ok(node_assigns))
    |> assign_size_async(node_assigns)
    |> noreply()
  end

  def handle_async(:node_assigns, {:exit, reason}, socket) do
    socket
    |> assign(:node_assigns, AsyncResult.failed(%AsyncResult{}, reason))
    |> noreply()
  end

  def handle_async(ev, {:ok, assigns_sizes}, socket) when ev in @assigns_size_events do
    socket
    |> assign(:assigns_sizes, AsyncResult.ok(assigns_sizes))
    |> noreply()
  end

  def handle_async(ev, {:exit, {reason, _}}, socket) when ev in @assigns_size_events do
    socket
    |> assign(:assigns_sizes, AsyncResult.failed(%AsyncResult{}, reason))
    |> noreply()
  end

  defp assign_async_node_assigns(
         %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket
       )
       when not is_nil(node_id) do
    start_async(socket, :node_assigns, fn ->
      case NodeStateQueries.fetch_node_assigns(pid, node_id) do
        {:ok, %{node_assigns: node_assigns}} ->
          node_assigns

        {:error, reason} ->
          raise reason
      end
    end)
  end

  defp assign_async_node_assigns(socket) do
    assign(socket, :node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  # If one async task is already running, we start the second async task
  # If both async tasks are running, we start the second async task
  # It stops already running second async tasks and start a new one
  defp assign_size_async(%{private: %{live_async: %{assigns_size_1: _}}} = socket, assigns) do
    start_async(socket, :assigns_size_2, fn -> calculate_assigns_size(assigns) end)
  end

  # If assigns are not calculated, we start the first async task
  defp assign_size_async(socket, assigns) do
    start_async(socket, :assigns_size_1, fn -> calculate_assigns_size(assigns) end)
  end

  defp calculate_assigns_size(assigns) do
    %{heap_size: assigns_heap_size(assigns), serialized_size: assigns_serialized_size(assigns)}
  end

  defp assigns_heap_size(assigns) do
    assigns |> Memory.term_heap_size() |> Memory.bytes_to_pretty_string()
  end

  defp assigns_serialized_size(assigns) do
    assigns |> Memory.serialized_term_size() |> Memory.bytes_to_pretty_string()
  end
end
