defmodule LiveDebugger.LiveViews.ChannelDashboard do
  @moduledoc false

  use LiveDebuggerWeb, :live_view

  require Logger

  alias LiveDebugger.Components
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Structs.TreeNode
  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Services.CallbackTracingService
  alias LiveDebugger.Services.ChannelService

  @impl true
  def mount(%{"socket_id" => socket_id}, _session, socket) do
    socket
    |> assign(:socket_id, socket_id)
    |> assign(:tracing_session, nil)
    |> assign_async_debugged_pid()
    |> assign_base_url()
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket
    |> assign_node_id(params)
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.async_result :let={pid} assign={@debugged_pid}>
      <:loading>
        <div class="h-full flex items-center justify-center">
          <.spinner size="md" />
        </div>
      </:loading>
      <:failed :let={reason}>
        <Components.not_found_component :if={reason == :not_found} socket={@socket} />
        <Components.error_component :if={reason != :not_found} />
      </:failed>

      <div class="flex flex-row w-full min-h-screen">
        <.live_component
          module={LiveDebugger.LiveComponents.Sidebar}
          id="sidebar"
          pid={pid}
          socket_id={@socket_id}
          node_id={@node_id || pid}
          base_url={@base_url}
        />
        <.live_component
          module={LiveDebugger.LiveComponents.DetailView}
          id="detail_view"
          pid={pid}
          node_id={@node_id || pid}
          socket_id={@socket_id}
        />
      </div>
    </.async_result>
    """
  end

  @impl true
  def handle_async(:fetch_debugged_pid, {:ok, nil}, socket) do
    with [live_pid] <- LiveViewDiscoveryService.live_pids(),
         {:ok, %{socket: %{id: socket_id}}} <- ChannelService.state(live_pid) do
      socket
      |> push_navigate(to: "#{live_debugger_base_url(socket)}/#{socket_id}")
      |> noreply()
    else
      _ ->
        socket
        |> assign(:debugged_pid, AsyncResult.failed(socket.assigns.debugged_pid, :not_found))
        |> noreply()
    end
  end

  @impl true
  def handle_async(:fetch_debugged_pid, {:ok, fetched_pid}, socket) do
    Process.monitor(fetched_pid)

    {:ok, tracing_session} =
      CallbackTracingService.start_tracing_session(socket.assigns.socket_id, fetched_pid, self())

    socket
    |> assign(:debugged_pid, AsyncResult.ok(fetched_pid))
    |> assign(:tracing_session, tracing_session)
    |> noreply()
  end

  @impl true
  def handle_async(:fetch_debugged_pid, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching debugged pid: #{inspect(reason)}"
    )

    socket
    |> assign(:debugged_pid, AsyncResult.failed(socket.assigns.debugged_pid, reason))
    |> noreply()
  end

  @impl true
  def handle_info({:DOWN, _, :process, _closed_pid, _}, socket) do
    CallbackTracingService.stop_tracing_session(socket.assigns.tracing_session)

    socket
    |> push_patch(to: socket.assigns.base_url)
    |> assign_async_debugged_pid()
    |> noreply()
  end

  @impl true
  def handle_info({:new_trace, trace}, socket) do
    debugged_node_id = socket.assigns.node_id || socket.assigns.debugged_pid.result

    if Trace.node_id(trace) == debugged_node_id do
      Logger.debug("New trace matched debugged node: \n#{inspect(trace)}")

      send_update(LiveDebugger.LiveComponents.EventsList, %{id: "event-list", new_trace: trace})
      send_update(LiveDebugger.LiveComponents.DetailView, %{id: "detail_view", new_trace: trace})
    else
      Logger.debug("New trace coming from different node - ignoring: #{inspect(trace)}")
    end

    send_update(LiveDebugger.LiveComponents.Sidebar, %{id: "sidebar", new_trace: trace})

    socket =
      if Trace.live_component_delete?(trace) and Trace.node_id(trace) == debugged_node_id do
        push_patch(socket, to: socket.assigns.base_url)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    CallbackTracingService.stop_tracing_session(socket.assigns.tracing_session)
  end

  defp assign_node_id(socket, %{"node_id" => node_id}) do
    case TreeNode.id_from_string(node_id) do
      {:ok, id} ->
        assign(socket, :node_id, id)

      :error ->
        Logger.error("Invalid node_id: #{inspect(node_id)}")
        assign(socket, :node_id, nil)
    end
  end

  defp assign_node_id(socket, _params) do
    assign(socket, :node_id, nil)
  end

  defp assign_base_url(socket) do
    assign(socket, :base_url, "#{live_debugger_base_url(socket)}/#{socket.assigns.socket_id}")
  end

  defp assign_async_debugged_pid(socket) do
    socket_id = socket.assigns.socket_id

    socket
    |> assign(:debugged_pid, AsyncResult.loading())
    |> start_async(:fetch_debugged_pid, fn ->
      with nil <- fetch_pid_after(socket_id, 200),
           nil <- fetch_pid_after(socket_id, 800) do
        fetch_pid_after(socket_id, 1000)
      end
    end)
  end

  defp fetch_pid_after(socket_id, milliseconds) do
    Process.sleep(milliseconds)
    LiveViewDiscoveryService.live_pid(socket_id)
  end
end
