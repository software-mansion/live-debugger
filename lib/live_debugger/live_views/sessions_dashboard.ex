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
    <div class="w-full h-full flex flex-col items-center">
      <.topbar return_link?={false} />
      <div class="w-full h-full p-8 xl:w-2/3">
        <div class="flex gap-4 items-center justify-between">
          <.h1>Active LiveViews</.h1>
          <.button phx-click="refresh" variant="tertiary">
            <div class="flex items-center gap-2">
              <.icon name="icon-refresh" class="w-4 h-4" />
              <p>Refresh</p>
            </div>
          </.button>
        </div>

        <div class="mt-6">
          <.async_result :let={live_sessions} assign={@live_sessions}>
            <:loading>
              <div class="flex items-center justify-center">
                <.spinner size="md" />
              </div>
            </:loading>
            <:failed>
              <.alert variant="danger" with_icon heading="Error fetching active LiveViews">
                Check logs for more
              </.alert>
            </:failed>
            <div>
              <%= if Enum.empty?(live_sessions)  do %>
                <div class="p-4 bg-white rounded shadow-custom border border-secondary-200">
                  <p class="text-secondary-500 text-center">No active LiveViews</p>
                </div>
              <% else %>
                <.table
                  rows={live_sessions}
                  class="hidden sm:block"
                  on_row_click="session-picked"
                  row_attributes_fun={fn row -> %{"phx-value-socket_id" => row.socket_id} end}
                >
                  <:column :let={session} label="Module" class="font-medium">
                    <%= session.module %>
                  </:column>
                  <:column :let={session} label="PID">
                    <%= Parsers.pid_to_string(session.pid) %>
                  </:column>
                  <:column :let={session} label="Socket"><%= session.socket_id %></:column>
                  <:column :let={session}>
                    <.badge :if={LiveDebugger.Utils.nested?(session)} />
                  </:column>
                </.table>
                <.list
                  elements={live_sessions}
                  class="sm:hidden"
                  on_element_click="session-picked"
                  element_attributes_fun={fn elem -> %{"phx-value-socket_id" => elem.socket_id} end}
                >
                  <:title :let={session}>
                    <div class="flex items-center justify-between">
                      <p class="shrink truncate"><%= session.module %></p>
                      <.badge :if={LiveDebugger.Utils.nested?(session)} />
                    </div>
                  </:title>
                  <:description :let={session}>
                    <%= Parsers.pid_to_string(session.pid) %> · <%= session.socket_id %>
                  </:description>
                </.list>
              <% end %>
            </div>
          </.async_result>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("session-picked", %{"socket_id" => socket_id}, socket) do
    socket
    |> push_navigate(to: "/#{socket_id}")
    |> noreply()
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
