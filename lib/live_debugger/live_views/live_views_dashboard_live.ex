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
    |> assign_async_groupped_lv_processes()
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full min-w-[25rem] flex flex-col items-center">
      <.navbar return_link?={false} />
      <div class="max-lg:p-8 pt-8 w-full lg:max-w-[40rem] h-full">
        <div class="flex gap-4 items-center justify-between">
          <.h1>Active LiveViews</.h1>
          <.button phx-click="refresh">
            <div class="flex items-center gap-2">
              <.icon name="icon-refresh" class="w-4 h-4" />
              <p>Refresh</p>
            </div>
          </.button>
        </div>

        <div class="mt-6">
          <.async_result :let={groupped_lv_processes} assign={@groupped_lv_processes}>
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
            <div class="flex flex-col gap-4">
              <%= if Enum.empty?(groupped_lv_processes)  do %>
                <div class="p-4 bg-surface-0-bg rounded shadow-custom border border-default-border">
                  <p class="text-secondary-text text-center">No active LiveViews</p>
                </div>
              <% else %>
                <.tab_section
                  :for={{transport_pid, lv_processes} <- groupped_lv_processes}
                  transport_pid={transport_pid}
                  lv_processes={lv_processes}
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
    |> assign(:groupped_lv_processes, AsyncResult.loading())
    |> assign_async_groupped_lv_processes()
    |> noreply()
  end

  attr(:transport_pid, :any, required: true)
  attr(:lv_processes, :list, required: true)

  defp tab_section(assigns) do
    assigns = assign(assigns, :lv_processes_length, length(assigns.lv_processes))

    ~H"""
    <div class="w-full h-max flex flex-col shadow-custom rounded-sm bg-surface-2-bg border border-default-border">
      <div class="pl-4 p-3 flex items-center h-10 border-b border-default-border">
        <p class="text-primary-text text-xs font-medium">
          <%= Parsers.pid_to_string(@transport_pid) %>
        </p>
      </div>
      <.list elements={Enum.with_index(@lv_processes)}>
        <:item :let={{lv_process, index}}>
          <div class="flex items-center w-full">
            <.nested_indent :if={lv_process.nested?} last?={index == @lv_processes_length} />
            <.list_element lv_process={lv_process} />
          </div>
        </:item>
      </.list>
    </div>
    """
  end

  attr(:last?, :boolean, required: true)

  defp nested_indent(assigns) do
    ~H"""
    <div class="relative w-8 h-12">
      <div class={[
        "absolute top-0 right-2 w-1/4 h-1/2 border-b border-default-border",
        if(not @last?, do: "border-l")
      ]}>
      </div>
      <div :if={@last?} class="absolute top-0 left-2 w-1/4 h-full border-r border-default-border">
      </div>
    </div>
    """
  end

  attr(:lv_process, LiveDebugger.Structs.LvProcess, required: true)

  defp list_element(assigns) do
    ~H"""
    <div
      role="button"
      class="flex justify-between items-center h-full w-full text-xs p-1.5 hover:bg-surface-0-bg-hover rounded-sm"
      phx-click="lv-process-picked"
      phx-value-socket-id={@lv_process.socket_id}
      phx-value-transport-pid={Parsers.pid_to_string(@lv_process.transport_pid)}
    >
      <div class="flex flex-col gap-1">
        <div class="text-link-primary flex items-center gap-1">
          <.icon :if={not @lv_process.nested?} name="icon-liveview" class="w-4 h-4" />
          <p class={if(not @lv_process.nested?, do: "font-medium")}><%= @lv_process.module %></p>
        </div>
        <p class="text-secondary-text">
          <%= Parsers.pid_to_string(@lv_process.pid) %> &middot; <%= @lv_process.socket_id %>
        </p>
      </div>
      <div>
        <.badge
          :if={@lv_process.embedded? and not @lv_process.nested?}
          text="Embedded"
          icon="icon-code"
        />
      </div>
    </div>
    """
  end

  defp assign_async_groupped_lv_processes(socket) do
    assign_async(socket, :groupped_lv_processes, fn ->
      lv_processes =
        with [] <- fetch_lv_processes_after(200),
             [] <- fetch_lv_processes_after(800) do
          fetch_lv_processes_after(1000)
        end

      groupped_lv_processes =
        lv_processes
        |> Enum.group_by(& &1.transport_pid)
        |> Enum.map(fn {transport_pid, lv_processes} ->
          {transport_pid, sort_with_nested_by_root_pid(lv_processes)}
        end)
        |> Enum.sort_by(fn {transport_pid, _} -> transport_pid end)

      {:ok, %{groupped_lv_processes: groupped_lv_processes}}
    end)
  end

  defp sort_with_nested_by_root_pid(lv_processes) do
    lv_processes
    |> Enum.group_by(& &1.root_pid)
    |> Enum.map(fn {root_pid, lv_processes} ->
      {root_pid, Enum.sort(lv_processes, fn lvp1, _lvp2 -> lvp1.root_pid == lvp1.pid end)}
    end)
    |> Enum.flat_map(&elem(&1, 1))
  end

  defp fetch_lv_processes_after(milliseconds) do
    Process.sleep(milliseconds)

    LiveViewDiscoveryService.debugged_lv_processes()
  end
end
