defmodule LiveDebugger.LiveViews.SessionsDashboard do
  use LiveDebuggerWeb, :live_view

  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Components

  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    socket
    |> assign_async_live_sessions()
    |> noreply()
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="w-full h-full p-2">
      <div class="pt-2">
        <.h2 class="text-swm-blue">Active LiveSessions</.h2>
      </div>

      <.async_result :let={live_sessions} assign={@live_sessions}>
        <:loading>
          <div class="h-full flex items-center justify-center">
            <.spinner size="md" />
          </div>
        </:loading>
        <:failed><Components.error_component /></:failed>
        <div :if={Enum.empty?(live_sessions)} class="text-gray-600">
          No LiveSessions found - try refreshing the page
        </div>

        <%= for session <- live_sessions do %>
          <Components.tooltip content={"Module: #{session.module}<br/>PID: #{Parsers.pid_to_string(session.pid)}"}>
            <.link
              class="text-swm-blue p-1font-medium "
              patch={"#{live_debugger_base_url(@socket)}/#{session.socket_id}"}
            >
              {session[:socket_id]}
            </.link>
          </Components.tooltip>
        <% end %>
      </.async_result>
    </div>
    """
  end

  defp assign_async_live_sessions(socket) do
    assign_async(socket, :live_sessions, fn ->
      live_sessions =
        with [] <- fetch_live_sessions_after(200),
             [] <- fetch_live_sessions_after(800) do
          fetch_live_sessions_after(1000)
        end

      {:ok, %{live_sessions: live_sessions}}
    end)
  end

  defp fetch_live_sessions_after(milliseconds) do
    Process.sleep(milliseconds)

    LiveViewDiscoveryService.live_pids()
    |> Enum.map(&live_session_info/1)
    |> Enum.reject(&(&1 == :error))
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
