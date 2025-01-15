defmodule LiveDebugger.LiveViews.SessionsDashboard do
  use LiveDebuggerWeb, :live_view

  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Services.ChannelService

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign_live_sessions()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full p-2">
      <h1>Sessions Dashboard</h1>
      <%= for session <- @live_sessions do %>
        <.link patch={"#{live_debugger_base_url(@socket)}/#{session.socket_id}"}>
          {session[:view]}
        </.link>
      <% end %>
    </div>
    """
  end

  defp assign_live_sessions(socket) do
    live_sessions =
      LiveViewDiscoveryService.live_pids()
      |> Enum.map(&live_session_info/1)

    assign(socket, :live_sessions, live_sessions)
  end

  defp live_session_info(pid) do
    pid
    |> ChannelService.state()
    |> case do
      {:ok, %{socket: %{id: id, view: view}}} -> %{socket_id: id, view: view}
      _ -> :error
    end
  end
end
