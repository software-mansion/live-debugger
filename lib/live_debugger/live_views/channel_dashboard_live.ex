defmodule LiveDebugger.LiveViews.ChannelDashboardLive do
  @moduledoc false

  use LiveDebuggerWeb, :live_view

  require Logger

  alias Phoenix.LiveView.JS
  alias LiveDebugger.Utils.URL
  alias Phoenix.LiveView.AsyncResult

  alias LiveDebugger.Components.Error
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Services.CallbackTracingService
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.LiveHelpers.Routes

  alias LiveDebugger.LiveViews.StateLive
  alias LiveDebugger.LiveViews.TracesLive
  alias LiveDebugger.LiveViews.SidebarLive
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  @impl true
  def mount(params, _session, socket) do
    socket
    |> assign(:tracing_session, nil)
    |> assign(:socket_id, params["socket_id"])
    |> start_async_assign_lv_process(params)
    |> ok()
  end

  @impl true
  def handle_params(params, url, socket) do
    socket
    |> assign_node_id(params)
    |> assign(:url, URL.to_relative(url))
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-screen h-screen flex flex-col">
      <.navbar return_link?={true}>
        <div class="grow flex items-center justify-end">
          <.nav_icon
            :if={@lv_process.ok?}
            phx-click={JS.push("open-sidebar", target: "#sidebar")}
            class="flex sm:hidden"
            icon="icon-menu-hamburger"
          />
        </div>
      </.navbar>
      <.async_result :let={lv_process} assign={@lv_process}>
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
          <SidebarLive.live_render
            id="sidebar"
            socket={@socket}
            lv_process={lv_process}
            url={@url}
            node_id={@node_id}
          />

          <div class="flex flex-col flex-1 h-full overflow-auto">
            <div class="overflow-auto grow p-8 items-center justify-start lg:items-start lg:justify-center flex flex-col lg:flex-row gap-4 lg:gap-8">
              <div class="w-full lg:w-1/2">
                <StateLive.live_render
                  id="node-state-lv"
                  socket={@socket}
                  lv_process={lv_process}
                  node_id={@node_id || lv_process.pid}
                />
              </div>

              <div class="w-full lg:w-1/2">
                <TracesLive.live_render
                  id="traces-list"
                  socket={@socket}
                  lv_process={lv_process}
                  node_id={@node_id || lv_process.pid}
                />
              </div>
            </div>
          </div>
        </div>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_async(:fetch_lv_process, {:ok, nil}, socket) do
    with %{debugged_module: module} when not is_nil(module) <- socket.assigns,
         [lv_process] <- LiveViewDiscoveryService.successor_lv_processes(module) do
      socket
      |> push_navigate(
        to: Routes.channel_dashboard(lv_process.socket_id, lv_process.transport_pid)
      )
      |> noreply()
    else
      _ ->
        socket
        |> assign(
          :lv_process,
          AsyncResult.failed(socket.assigns.lv_process, :not_found)
        )
        |> noreply()
    end
  end

  def handle_async(:fetch_lv_process, {:ok, fetched_lv_process}, socket) do
    Process.monitor(fetched_lv_process.pid)

    socket.assigns.socket_id
    |> CallbackTracingService.start_tracing(fetched_lv_process.pid, self())
    |> case do
      {:ok, tracing_session} ->
        socket
        |> assign(:lv_process, AsyncResult.ok(fetched_lv_process))
        |> assign(:debugged_module, fetched_lv_process.module)
        |> assign(:tracing_session, tracing_session)

      {:error, reason} ->
        assign(
          socket,
          :lv_process,
          AsyncResult.failed(socket.assigns.lv_process, reason)
        )
    end
    |> patch_transport_pid(fetched_lv_process)
    |> noreply()
  end

  def handle_async(:fetch_lv_process, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching information for process: #{inspect(reason)}"
    )

    socket
    |> assign(
      :lv_process,
      AsyncResult.failed(socket.assigns.lv_process, reason)
    )
    |> noreply()
  end

  @impl true
  def handle_info({:DOWN, _, :process, _closed_pid, _}, socket) do
    CallbackTracingService.stop_tracing(socket.assigns.tracing_session)

    socket
    |> start_async_assign_lv_process(%{"socket_id" => socket.assigns.socket_id})
    |> noreply()
  end

  @impl true
  def handle_info({:new_trace, trace}, socket) do
    debugged_node_id =
      socket.assigns.node_id ||
        (socket.assigns.lv_process.result &&
           socket.assigns.lv_process.result.pid)

    if Trace.node_id(trace) == debugged_node_id do
      socket.assigns.lv_process.result
      |> case do
        nil ->
          :ok

        lv_process ->
          lv_process
          |> PubSubUtils.new_trace_topic()
          |> PubSubUtils.broadcast({:new_trace, trace})
      end
    end

    send_update(LiveDebugger.LiveComponents.Sidebar, %{id: "sidebar", new_trace: trace})

    socket =
      if Trace.live_component_delete?(trace) and Trace.node_id(trace) == debugged_node_id do
        url = URL.remove_query_param(socket.assigns.url, "node_id")
        push_patch(socket, to: url)
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
        socket.id
        |> PubSubUtils.node_changed_topic()
        |> PubSubUtils.broadcast({:node_changed, id})

        assign(socket, :node_id, id)

      :error ->
        Logger.error("Invalid node_id: #{inspect(node_id)}")
        assign(socket, :node_id, nil)
    end
  end

  defp assign_node_id(socket, _params) do
    assign(socket, :node_id, nil)
  end

  defp start_async_assign_lv_process(socket, %{
         "socket_id" => socket_id,
         "transport_pid" => transport_pid
       }) do
    case Parsers.string_to_pid(transport_pid) do
      {:ok, pid} ->
        socket
        |> assign(:lv_process, AsyncResult.loading())
        |> start_async(:fetch_lv_process, fn ->
          fetch_lv_process(socket_id, pid)
        end)

      :error ->
        assign(
          socket,
          :lv_process,
          AsyncResult.failed(AsyncResult.loading(), :invalid_transport_pid)
        )
    end
  end

  defp start_async_assign_lv_process(socket, %{"socket_id" => socket_id}) do
    socket
    |> assign(:lv_process, AsyncResult.loading())
    |> start_async(:fetch_lv_process, fn ->
      fetch_lv_process(socket_id)
    end)
  end

  defp fetch_lv_process(socket_id, transport_pid \\ nil) do
    fetch_after = fn milliseconds ->
      Process.sleep(milliseconds)
      LiveViewDiscoveryService.lv_process(socket_id, transport_pid)
    end

    with nil <- fetch_after.(200),
         nil <- fetch_after.(800) do
      fetch_after.(1000)
    end
  end

  defp patch_transport_pid(socket, lv_process) do
    path = Routes.channel_dashboard(lv_process.socket_id, lv_process.transport_pid)
    url = URL.update_path(socket.assigns.url, path)

    push_patch(socket, to: url)
  end
end
