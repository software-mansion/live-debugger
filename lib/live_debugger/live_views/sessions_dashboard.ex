defmodule LiveDebugger.LiveViews.SessionsDashboard do
  use LiveDebuggerWeb, :live_view

  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Components

  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    socket
    |> assign_live_sessions()
    |> noreply()
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="w-full p-2">
      <div class="pt-2">
        <.h2 class="text-swm-blue">Active LiveSessions</.h2>
      </div>

      <%= for session <- @live_sessions do %>
        <Components.tooltip content={"Module: #{session.module}<br/>PID: #{Parsers.pid_to_string(session.pid)}"}>
          <.link
            class="text-swm-blue p-1font-medium "
            patch={"#{live_debugger_base_url(@socket)}/#{session.socket_id}"}
          >
            {session[:socket_id]}
          </.link>
        </Components.tooltip>
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
      {:ok, %{socket: %{id: id, view: module}}} -> %{socket_id: id, module: module, pid: pid}
      _ -> :error
    end
  end
end
