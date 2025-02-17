defmodule LiveDebugger.LiveViews.SessionsDashboard do
  @moduledoc """
  It displays all active LiveView sessions in the debugged application.
  """

  use LiveDebuggerWeb, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Services.ChannelService

  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    socket
    |> assign_async_live_sessions()
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full bg-primary-20 flex flex-col items-center">
      <.topbar return_link?={false} />
      <div class="w-full h-full p-8 xl:w-2/3">
        <.async_result :let={live_sessions} assign={@live_sessions}>
          <:loading>
            <div class="h-full flex items-center justify-center">
              <.spinner size="xl" />
            </div>
          </:loading>
          <:failed><.error_component /></:failed>
          <div class="flex gap-4 items-center justify-between">
            <div class="text-primary font-semibold text-2xl">Active LiveSessions</div>
            <.button phx-click="refresh" variant="outline">
              <div class="flex items-center gap-2">
                <.icon name="icon-refresh" class="w-4 h-4" />
                <p>Refresh</p>
              </div>
            </.button>
          </div>

          <div class="mt-6">
            <%= if Enum.empty?(live_sessions)  do %>
              <div class="text-gray-600">
                No LiveSessions found - try refreshing.
              </div>
            <% else %>
              <.table rows={live_sessions} wrapper_class="hidden sm:block">
                <:column :let={session} label="Module">
                  <.link class="text-primary" patch={"/#{session.socket_id}"}>
                    <%= session.module %>
                  </.link>
                </:column>
                <:column :let={session} label="PID">
                  <%= Parsers.pid_to_string(session.pid) %>
                </:column>
                <:column :let={session} label="Socket"><%= session.socket_id %></:column>
              </.table>
            <% end %>
          </div>
        </.async_result>
      </div>
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
