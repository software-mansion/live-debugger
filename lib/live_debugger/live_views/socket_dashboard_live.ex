defmodule LiveDebugger.LiveViews.SocketDashboardLive do
  use LiveDebuggerWeb, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Service.LiveViewScraper

  @impl true
  def mount(%{"socket_id" => socket_id}, _session, socket) do
    socket
    |> assign(:socket_id, socket_id)
    |> assign_async_debugged_pid()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.container max_width="full">
      <div :if={@debugged_pid.loading}><.spinner size="lg" /></div>
      <div :if={@debugged_pid.ok?}>
        <div>Monitored socket: <span class="text-blue-500">{@socket_id}</span></div>
        <div>Debugged PID: <span class="text-blue-500">{inspect(@debugged_pid.result)}</span></div>
      </div>
    </.container>
    """
  end

  @impl true
  def handle_async(:fetch_debugged_pid, {:ok, nil}, socket) do
    socket
    |> assign(:debugged_pid, AsyncResult.ok(socket.assigns.debugged_pid, nil))
    |> noreply()
  end

  @impl true
  def handle_async(:fetch_debugged_pid, {:ok, fetched_pid}, socket) do
    socket
    |> assign(:debugged_pid, AsyncResult.ok(socket.assigns.debugged_pid, fetched_pid))
    |> noreply()
  end

  defp assign_async_debugged_pid(socket) do
    socket_id = socket.assigns.socket_id

    socket
    |> assign(:debugged_pid, AsyncResult.loading())
    |> start_async(:fetch_debugged_pid, fn -> LiveViewScraper.pid_by_socket_id(socket_id) end)
  end
end
