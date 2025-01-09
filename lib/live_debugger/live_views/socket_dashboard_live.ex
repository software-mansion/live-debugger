defmodule LiveDebugger.LiveViews.SocketDashboardLive do
  use LiveDebuggerWeb, :live_view

  require Logger

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Services.TreeNode
  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Services.LiveViewScraper
  alias LiveDebugger.Services.CallbackTracer

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
    <.loading_variant :if={@debugged_pid.loading} />
    <.not_found_component :if={@debugged_pid.failed == :not_found} />
    <.error_component :if={not @debugged_pid.ok? and @debugged_pid.failed != :not_found} />
    <.content
      :if={@debugged_pid.ok?}
      pid={@debugged_pid.result}
      node_id={@node_id}
      socket_id={@socket_id}
      base_url={@base_url}
    />
    """
  end

  @impl true
  def handle_async(:fetch_debugged_pid, {:ok, nil}, socket) do
    socket
    |> assign(:debugged_pid, AsyncResult.failed(socket.assigns.debugged_pid, :not_found))
    |> noreply()
  end

  @impl true
  def handle_async(:fetch_debugged_pid, {:ok, fetched_pid}, socket) do
    Process.monitor(fetched_pid)

    {:ok, tracing_session} =
      CallbackTracer.start_tracing_session(socket.assigns.socket_id, fetched_pid, self())

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
    CallbackTracer.stop_tracing_session(socket.assigns.tracing_session)

    socket
    |> assign_async_debugged_pid()
    |> noreply()
  end

  def handle_info({:new_trace, trace}, socket) do
    debugged_node_id = socket.assigns.node_id || socket.assigns.debugged_pid.result

    if Trace.node_id(trace) == debugged_node_id do
      Logger.debug("Received a new trace: \n#{inspect(trace)}")

      send_update(LiveDebugger.LiveComponents.EventsList, %{id: "event-list", new_trace: trace})

      send_update(LiveDebugger.LiveComponents.DetailView, %{
        id: "detail_view",
        pid: socket.assigns.debugged_pid.result,
        socket_id: socket.assigns.socket_id,
        node_id: debugged_node_id
      })
    else
      Logger.debug("Ignoring a trace from different node: #{inspect(trace)}")
    end

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    CallbackTracer.stop_tracing_session(socket.assigns.tracing_session)
  end

  defp loading_variant(assigns) do
    ~H"""
    <div class="h-full flex items-center justify-center">
      <.spinner size="md" />
    </div>
    """
  end

  defp not_found_component(assigns) do
    ~H"""
    <div class="h-full flex flex-col items-center justify-center mx-8">
      <.icon name="hero-exclamation-circle" class="w-16 h-16" />
      <.h2 class="text-center">Debugger disconnected</.h2>
      <.h5 class="text-center">
        We couldn't find any LiveView associated with the given socket id
      </.h5>
      <span>You can close this window</span>
    </div>
    """
  end

  defp error_component(assigns) do
    ~H"""
    <div class="h-full flex flex-col items-center justify-center mx-8">
      <.icon name="hero-exclamation-circle" class="w-16 h-16" />
      <.h2 class="text-center">Unexpected error</.h2>
      <.h5 class="text-center">
        Debugger encountered unexpected error - check logs for more
      </.h5>
      <span>You can close this window</span>
    </div>
    """
  end

  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)
  attr(:node_id, :string, required: true)
  attr(:base_url, :string, required: true)

  defp content(assigns) do
    assigns = assign(assigns, :node_id, assigns.node_id || assigns.pid)

    ~H"""
    <div class="flex flex-row w-full min-h-screen">
      <.live_component
        module={LiveDebugger.LiveComponents.Sidebar}
        id="sidebar"
        pid={@pid}
        socket_id={@socket_id}
        node_id={@node_id}
        base_url={@base_url}
      />
      <.live_component
        module={LiveDebugger.LiveComponents.DetailView}
        id="detail_view"
        pid={@pid}
        node_id={@node_id}
        socket_id={@socket_id}
      />
    </div>
    """
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
    prefix = socket.router.live_debugger_prefix()

    assign(socket, :base_url, "#{prefix}/#{socket.assigns.socket_id}")
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
    LiveViewScraper.pid_by_socket_id(socket_id)
  end
end
