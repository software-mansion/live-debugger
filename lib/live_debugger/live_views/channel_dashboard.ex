defmodule LiveDebugger.LiveViews.ChannelDashboard do
  @moduledoc false

  use LiveDebuggerWeb, :live_view

  require Logger

  alias LiveDebugger.Components.Error
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Structs.TreeNode
  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Services.CallbackTracingService

  @impl true
  def mount(%{"socket_id" => socket_id}, _session, socket) do
    socket
    |> assign(:socket_id, socket_id)
    |> assign(:tracing_session, nil)
    |> assign(:debugged_module, nil)
    |> assign_rate_limiter_pid()
    |> assign_async_debugged_lv_process()
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
    <div class="w-screen h-screen flex flex-col">
      <.topbar return_link?={true}>
        <div class="grow flex items-center justify-end">
          <.icon_button phx-click="open-sidebar" class="flex sm:hidden" icon="icon-menu-hamburger" />
        </div>
      </.topbar>
      <.async_result :let={lv_process} assign={@debugged_lv_process}>
        <:loading>
          <div class="h-full flex items-center justify-center">
            <.spinner size="xl" />
          </div>
        </:loading>
        <:failed :let={reason}>
          <Error.not_found_component :if={reason == :not_found} />
          <Error.session_limit_component :if={reason == :session_limit} />
          <Error.unexpected_error_component :if={reason not in [:not_found, :session_limit]} />
        </:failed>

        <div class="flex grow w-full overflow-y-auto">
          <.live_component
            module={LiveDebugger.LiveComponents.Sidebar}
            id="sidebar"
            lv_process={lv_process}
            node_id={@node_id}
            base_url={@base_url}
          />
          <.live_component
            module={LiveDebugger.LiveComponents.DetailView}
            id="detail_view"
            lv_process={lv_process}
            node_id={@node_id}
          />
        </div>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("open-sidebar", _, socket) do
    send_update(LiveDebugger.LiveComponents.Sidebar, %{id: "sidebar", show_sidebar?: true})

    noreply(socket)
  end

  @impl true
  def handle_async(:fetch_debugged_lv_process, {:ok, nil}, socket) do
    case LiveViewDiscoveryService.successor_lv_processes(socket.assigns.debugged_module) do
      [lv_process] ->
        socket
        |> push_navigate(to: "/#{lv_process.socket_id}")
        |> noreply()

      _ ->
        socket
        |> assign(
          :debugged_lv_process,
          AsyncResult.failed(socket.assigns.debugged_lv_process, :not_found)
        )
        |> noreply()
    end
  end

  @impl true
  def handle_async(:fetch_debugged_lv_process, {:ok, fetched_lv_process}, socket) do
    Process.monitor(fetched_lv_process.pid)

    socket.assigns.socket_id
    |> CallbackTracingService.start_tracing(
      fetched_lv_process.pid,
      socket.assigns.rate_limiter_pid
    )
    |> case do
      {:ok, tracing_session} ->
        socket
        |> assign(:debugged_lv_process, AsyncResult.ok(fetched_lv_process))
        |> assign(:debugged_module, fetched_lv_process.module)
        |> assign(:tracing_session, tracing_session)

      {:error, reason} ->
        assign(
          socket,
          :debugged_lv_process,
          AsyncResult.failed(socket.assigns.debugged_lv_process, reason)
        )
    end
    |> noreply()
  end

  @impl true
  def handle_async(:fetch_debugged_lv_process, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching debugged pid: #{inspect(reason)}"
    )

    socket
    |> assign(
      :debugged_lv_process,
      AsyncResult.failed(socket.assigns.debugged_lv_process, reason)
    )
    |> noreply()
  end

  @impl true
  def handle_info({:DOWN, _, :process, _closed_pid, _}, socket) do
    CallbackTracingService.stop_tracing(socket.assigns.tracing_session)

    socket
    |> push_patch(to: socket.assigns.base_url)
    |> assign_async_debugged_lv_process()
    |> noreply()
  end

  @impl true
  def handle_info({:new_trace, %{trace: trace, counter: _} = wrapped_trace}, socket) do
    debugged_node_id =
      socket.assigns.node_id ||
        (socket.assigns.debugged_lv_process.result &&
           socket.assigns.debugged_lv_process.result.pid)

    if Trace.node_id(trace) == debugged_node_id do
      send_update(LiveDebugger.LiveComponents.TracesList, %{
        id: "trace-list",
        new_trace: wrapped_trace
      })

      send_update(LiveDebugger.LiveComponents.DetailView, %{id: "detail_view", new_trace: trace})
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
    CallbackTracingService.stop_tracing(socket.assigns.tracing_session)
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
    assign(socket, :base_url, "/#{socket.assigns.socket_id}")
  end

  defp assign_async_debugged_lv_process(socket) do
    socket_id = socket.assigns.socket_id

    socket
    |> assign(:debugged_lv_process, AsyncResult.loading())
    |> start_async(:fetch_debugged_lv_process, fn ->
      with nil <- fetch_lv_process_after(socket_id, 200),
           nil <- fetch_lv_process_after(socket_id, 800) do
        fetch_lv_process_after(socket_id, 1000)
      end
    end)
  end

  defp assign_rate_limiter_pid(socket) do
    if connected?(socket) do
      {:ok, pid} = LiveDebugger.Services.TraceRateLimiter.start_link()
      assign(socket, :rate_limiter_pid, pid)
    else
      assign(socket, :rate_limiter_pid, nil)
    end
  end

  defp fetch_lv_process_after(socket_id, milliseconds) do
    Process.sleep(milliseconds)
    LiveViewDiscoveryService.lv_process(socket_id)
  end
end
