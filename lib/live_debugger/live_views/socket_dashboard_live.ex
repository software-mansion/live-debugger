defmodule LiveDebugger.LiveViews.SocketDashboardLive do
  use LiveDebuggerWeb, :live_view

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
      <div :if={@debugged_pid.status == :loading}><.spinner /></div>
      <div :if={@debugged_pid.status == :ok}>
        <div>Monitored socket: <span class="text-blue-500">{@socket_id}</span></div>
        <div>Debugged PID: <span class="text-blue-500">{inspect(@debugged_pid.result)}</span></div>
      </div>
      <div :if={@debugged_pid.status == :not_found}>Process not found - debugger disconnected</div>
    </.container>
    """
  end

  @impl true
  def handle_async(:fetch_debugged_pid, {:ok, nil}, socket) do
    socket
    |> assign(:debugged_pid, %{status: :not_found, result: nil})
    |> noreply()
  end

  @impl true
  def handle_async(:fetch_debugged_pid, {:ok, fetched_pid}, socket) do
    Process.monitor(fetched_pid)

    socket
    |> assign(:debugged_pid, %{status: :ok, result: fetched_pid})
    |> noreply()
  end

  @impl true
  def handle_info({:DOWN, _, :process, _closed_pid, _}, socket) do
    socket
    |> assign_async_debugged_pid()
    |> noreply()
  end

  defp assign_async_debugged_pid(socket) do
    socket_id = socket.assigns.socket_id

    socket
    |> assign(:debugged_pid, %{status: :loading})
    |> start_async(:fetch_debugged_pid, fn ->
      with nil <- fetch_pid_with_after(socket_id, 200),
           nil <- fetch_pid_with_after(socket_id, 800),
           nil <- fetch_pid_with_after(socket_id, 1000) do
        nil
      else
        pid -> pid
      end
    end)
  end

  defp fetch_pid_with_after(socket_id, milliseconds) do
    Process.sleep(milliseconds)
    LiveViewScraper.pid_by_socket_id(socket_id)
  end
end
