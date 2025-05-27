defmodule LiveDebuggerWeb.LiveViewsDashboardLive do
  @moduledoc """
  It displays all active LiveView sessions in the debugged application.
  """

  use LiveDebuggerWeb, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebuggerWeb.Components.TabGroup
  alias LiveDebuggerWeb.Components.Navbar

  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    socket
    |> assign_async_grouped_lv_processes()
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 min-w-[25rem] grid grid-rows-[auto_1fr]">
      <Navbar.navbar class="flex justify-between">
        <Navbar.live_debugger_logo />
        <Navbar.settings_button />
      </Navbar.navbar>
      <div class="flex-1 max-lg:p-8 pt-8 lg:w-[60rem] lg:m-auto">
        <div class="flex items-center justify-between">
          <.h1>Active LiveViews</.h1>
          <.button phx-click="refresh">
            <div class="flex items-center gap-2">
              <.icon name="icon-refresh" class="w-4 h-4" />
              <p>Refresh</p>
            </div>
          </.button>
        </div>

        <div class="mt-6">
          <.async_result :let={grouped_lv_processes} assign={@grouped_lv_processes}>
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
            <div id="live-sessions" class="flex flex-col gap-4">
              <%= if Enum.empty?(grouped_lv_processes)  do %>
                <div class="p-4 bg-surface-0-bg rounded shadow-custom border border-default-border">
                  <p class="text-secondary-text text-center">No active LiveViews</p>
                </div>
              <% else %>
                <TabGroup.group
                  :for={{transport_pid, grouped_lv_processes} <- grouped_lv_processes}
                  transport_pid={transport_pid}
                  grouped_lv_processes={grouped_lv_processes}
                />
              <% end %>
            </div>
          </.async_result>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket
    |> assign(:grouped_lv_processes, AsyncResult.loading())
    |> assign_async_grouped_lv_processes()
    |> noreply()
  end

  defp assign_async_grouped_lv_processes(socket) do
    assign_async(socket, :grouped_lv_processes, fn ->
      lv_processes =
        with [] <- fetch_lv_processes_after(200),
             [] <- fetch_lv_processes_after(800) do
          fetch_lv_processes_after(1000)
        end

      {:ok, %{grouped_lv_processes: LiveViewDiscoveryService.group_lv_processes(lv_processes)}}
    end)
  end

  defp fetch_lv_processes_after(milliseconds) do
    Process.sleep(milliseconds)

    LiveViewDiscoveryService.debugged_lv_processes()
  end
end
