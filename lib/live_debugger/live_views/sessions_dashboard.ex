defmodule LiveDebugger.LiveViews.SessionsDashboard do
  @moduledoc """
  It displays all active LiveView sessions in the debugged application.
  """

  use LiveDebuggerWeb, :live_view

  import LiveDebugger.Components

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Services.ChannelService

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
      <div class="flex gap-4 items-center pt-2">
        <.h2 class="text-primary">Active LiveSessions</.h2>
        <.icon phx-click="refresh" name="hero-arrow-path" class="text-primary mb-3 cursor-pointer" />
      </div>

      <.async_result :let={live_sessions} assign={@live_sessions}>
        <:loading>
          <div class="h-full flex items-center justify-center">
            <.spinner size="md" />
          </div>
        </:loading>
        <:failed><.error_component /></:failed>
        <div :if={Enum.empty?(live_sessions)} class="text-gray-600">
          No LiveSessions found - try refreshing.
        </div>
        <ul>
          <li :for={{session, id} <- Enum.with_index(live_sessions)}>
            <.tooltip
              id={"session_" <> id}
              class="inline-block"
              content={"Module: #{session.module}<br/>PID: #{Parsers.pid_to_string(session.pid)}"}
            >
              <.link
                class="text-primary"
                patch={"#{live_debugger_base_url(@socket)}/#{session.socket_id}"}
              >
                {session[:socket_id]}
              </.link>
            </.tooltip>
          </li>
        </ul>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket
    |> assign(:live_sessions, AsyncResult.loading())
    |> assign_async_live_sessions()
    |> noreply()
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
