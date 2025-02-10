defmodule LiveDebugger.LiveViews.SessionsDashboardLive do
  @moduledoc """
  It displays all active LiveView sessions in the debugged application.
  """

  use LiveDebuggerWeb, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Structs.LiveViewProcess
  alias LiveDebugger.Utils.Parsers

  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    socket
    |> assign_async_live_view_processes()
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full p-2">
      <.async_result :let={live_view_processes} assign={@live_view_processes}>
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
          <%= if Enum.empty?(live_view_processes)  do %>
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
                <.table_row live_view_processes={live_view_processes} />
              </table>
            </div>
          <% end %>
        </div>
      </.async_result>
    </div>
    """
  end

  attr(:live_view_processes, :map, required: true)
  attr(:indent, :integer, default: 0)

  defp table_row(assigns) do
    assigns =
      assigns
      |> assign(:child?, assigns.indent > 0)
      |> assign(:padding, (assigns.indent + 1) * 0.5)
      |> assign(:next_indent, assigns.indent + 1)

    ~H"""
    <div>
      <%= for {process, children_processes} <- assigns.live_view_processes do %>
        <tr>
          <td class="text-left flex items-center" style={"padding-left: #{@padding}rem"}>
            <.icon :if={@child?} name="hero-arrow-turn-down-right-micro" class="text-primary-500" />
            <.link class="text-primary" patch={redirect_url(process)}>
              <%= process.module %>
            </.link>
          </td>
          <td class="hidden xs:table-cell text-center">
            <%= Parsers.pid_to_string(process.pid) %>
          </td>
          <td class="hidden sm:table-cell text-center"><%= process.socket_id %></td>
        </tr>
        <.table_row live_view_processes={children_processes} indent={@next_indent} />
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket
    |> assign(:live_view_processes, AsyncResult.loading())
    |> assign_async_live_view_processes()
    |> noreply()
  end

  defp assign_async_live_view_processes(socket) do
    assign_async(socket, :live_view_processes, fn ->
      live_view_processes =
        with [] <- fetch_live_view_processes_after(200),
             [] <- fetch_live_view_processes_after(800) do
          fetch_live_view_processes_after(1000)
        end

      {:ok,
       %{
         live_view_processes:
           LiveViewDiscoveryService.merge_live_view_processes(live_view_processes)
       }}
    end)
  end

  @spec fetch_live_view_processes_after(integer) :: [LiveViewProcess.t()]
  defp fetch_live_view_processes_after(milliseconds) do
    Process.sleep(milliseconds)

    LiveViewDiscoveryService.debugged_live_pids()
    |> LiveViewDiscoveryService.pids_to_live_view_processes()
  end

  defp redirect_url(%LiveViewProcess{root?: true, socket_id: socket_id}), do: "/#{socket_id}"

  defp redirect_url(%LiveViewProcess{root_socket_id: root_socket_id, socket_id: socket_id}),
    do: "/#{root_socket_id}/#{socket_id}"
end
