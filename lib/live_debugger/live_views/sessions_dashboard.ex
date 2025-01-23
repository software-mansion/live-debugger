defmodule LiveDebugger.LiveViews.SessionsDashboard do
  @moduledoc """
  It displays all active LiveView sessions in the debugged application.
  """

  use LiveDebuggerWeb, :live_view

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
      <.async_result :let={live_sessions} assign={@live_sessions}>
        <:loading>
          <div class="h-full flex items-center justify-center">
            <.spinner size="xl" />
          </div>
        </:loading>
        <:failed><.error_component /></:failed>
        <div class="flex gap-4 items-center pt-2">
          <.h2 class="text-primary">Active LiveSessions</.h2>
          <.icon phx-click="refresh" name="hero-arrow-path" class="text-primary cursor-pointer" />
        </div>

        <div class="mt-2 lg:mt-4 mx-1">
          <%= if Enum.empty?(live_sessions)  do %>
            <div class="text-gray-600">
              No LiveSessions found - try refreshing.
            </div>
          <% else %>
            <div class="border-2 border-primary rounded-md w-full lg:w-3/4 2xl:w-1/2 ">
              <table class="w-full">
                <tr class="border-b-2 border-primary">
                  <th>Module</th>
                  <th class="hidden xs:table-cell">PID</th>
                  <th class="hidden sm:table-cell">Socket ID</th>
                </tr>
                <tr :for={session <- live_sessions}>
                  <td class="text-center ">
                    <.link
                      class="text-primary"
                      patch={"#{live_debugger_base_url(@socket)}/#{session.socket_id}"}
                    >
                      <%= session.module %>
                    </.link>
                  </td>
                  <td class="hidden xs:table-cell text-center">
                    <%= Parsers.pid_to_string(session.pid) %>
                  </td>
                  <td class="hidden sm:table-cell text-center"><%= session.socket_id %></td>
                </tr>
              </table>
            </div>
          <% end %>
        </div>
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

    LiveViewDiscoveryService.debugged_live_pids()
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
