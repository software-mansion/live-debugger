defmodule LiveDebugger.LiveViews.LiveViewsDashboardLive do
  @moduledoc """
  It displays all active LiveView sessions in the debugged application.
  """

  use LiveDebuggerWeb, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.LiveHelpers.Routes

  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    socket
    |> assign_async_lv_processes()
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
          <.async_result :let={lv_processes} assign={@lv_processes}>
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
              <%= if Enum.empty?(lv_processes)  do %>
                <div class="p-4 bg-white rounded shadow-custom border border-secondary-200">
                  <p class="text-secondary-500 text-center">No active LiveViews</p>
                </div>
              <% else %>
                <.table
                  rows={lv_processes}
                  class="hidden sm:block"
                  on_row_click="lv-process-picked"
                  row_attributes_fun={&event_values_map/1}
                >
                  <:column :let={lv_process} label="Module" class="font-medium">
                    <%= lv_process.module %>
                  </:column>
                  <:column :let={lv_process} label="PID">
                    <%= Parsers.pid_to_string(lv_process.pid) %>
                  </:column>
                  <:column :let={lv_process} label="Socket"><%= lv_process.socket_id %></:column>
                  <:column :let={lv_process}>
                    <.badge :if={lv_process.nested?} text="Nested" icon="icon-nested" />
                  </:column>
                </.table>
                <.list
                  elements={lv_processes}
                  class="sm:hidden"
                  on_element_click="lv-process-picked"
                  element_attributes_fun={&event_values_map/1}
                >
                  <:title :let={lv_process}>
                    <div class="flex items-center justify-between">
                      <p class="shrink truncate"><%= lv_process.module %></p>
                      <.badge :if={lv_process.nested?} text="Nested" icon="icon-nested" />
                    </div>
                  </:title>
                  <:description :let={lv_process}>
                    <%= Parsers.pid_to_string(lv_process.pid) %> · <%= lv_process.socket_id %>
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
  def handle_event(
        "lv-process-picked",
        %{"socket-id" => socket_id, "transport-pid" => transport_pid},
        socket
      ) do
    socket
    |> push_navigate(to: Routes.channel_dashboard(socket_id, transport_pid))
    |> noreply()
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket
    |> assign(:lv_processes, AsyncResult.loading())
    |> assign_async_lv_processes()
    |> noreply()
  end

  defp event_values_map(lv_process) do
    %{
      "phx-value-socket-id" => lv_process.socket_id,
      "phx-value-transport-pid" => Parsers.pid_to_string(lv_process.transport_pid)
    }
  end

  defp assign_async_lv_processes(socket) do
    assign_async(socket, :lv_processes, fn ->
      lv_processes =
        with [] <- fetch_lv_processes_after(200),
             [] <- fetch_lv_processes_after(800) do
          fetch_lv_processes_after(1000)
        end

      {:ok, %{lv_processes: lv_processes}}
    end)
  end

  defp fetch_lv_processes_after(milliseconds) do
    Process.sleep(milliseconds)

    LiveViewDiscoveryService.debugged_lv_processes()
  end
end
