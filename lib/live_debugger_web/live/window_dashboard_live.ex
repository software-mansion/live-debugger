defmodule LiveDebuggerWeb.WindowDashboardLive do
  use LiveDebuggerWeb, :live_view

  alias LiveDebugger.Utils.Parsers
  alias LiveDebuggerWeb.Helpers.RoutesHelper
  alias LiveDebugger.Services.LiveViewDiscoveryService

  @impl true
  def mount(%{"transport_pid" => string_transport_pid}, _session, socket) do
    string_transport_pid
    |> Parsers.string_to_pid()
    |> case do
      {:ok, transport_pid} ->
        socket
        |> assign(:transport_pid, transport_pid)
        |> assign_async_lv_processes()

      :error ->
        push_navigate(socket, to: RoutesHelper.error("invalid_pid"))
    end
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>Window Dashboard</div>
    """
  end

  defp assign_async_lv_processes(%{assigns: %{transport_pid: transport_pid}} = socket) do
    assign_async(socket, :lv_processes, fn ->
      lv_processes =
        with [] <- fetch_lv_processes_after(200, transport_pid),
             [] <- fetch_lv_processes_after(800, transport_pid) do
          fetch_lv_processes_after(1000, transport_pid)
        end

      {:ok, %{lv_processes: lv_processes}}
    end)
  end

  defp fetch_lv_processes_after(milliseconds, transport_pid) do
    Process.sleep(milliseconds)

    LiveViewDiscoveryService.debugged_lv_processes(transport_pid)
  end
end
