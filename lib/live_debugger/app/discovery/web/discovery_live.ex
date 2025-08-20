defmodule LiveDebugger.App.Discovery.Web.DiscoveryLive do
  @moduledoc """
  LiveView page for discovering all active LiveView sessions in the debugged application.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.App.Discovery.Web.Components, as: DiscoveryComponents
  alias LiveDebugger.App.Web.Components.Navbar, as: NavbarComponents
  alias LiveDebugger.App.Discovery.Queries, as: DiscoveryQueries

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bus.receive_events!()
    end

    socket
    |> assign_async_grouped_lv_processes()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 min-w-[25rem] grid grid-rows-[auto_1fr]">
      <NavbarComponents.navbar class="flex justify-between">
        <NavbarComponents.live_debugger_logo />
        <NavbarComponents.settings_button return_to={@url} />
      </NavbarComponents.navbar>
      <div class="flex-1 max-lg:p-8 pt-8 lg:w-[60rem] lg:m-auto">
        <DiscoveryComponents.header title="Active LiveViews" />

        <div class="mt-6">
          <.async_result :let={grouped_lv_processes} assign={@grouped_lv_processes}>
            <:loading><DiscoveryComponents.loading /></:loading>
            <:failed><DiscoveryComponents.failed /></:failed>
            <DiscoveryComponents.live_sessions grouped_lv_processes={grouped_lv_processes} />
          </.async_result>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket
    |> assign_async_grouped_lv_processes()
    |> noreply()
  end

  @impl true
  def handle_info(%LiveViewBorn{}, socket) do
    socket
    |> assign_async_grouped_lv_processes()
    |> noreply()
  end

  def handle_info(%LiveViewDied{}, socket) do
    socket
    |> assign_async_grouped_lv_processes()
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp assign_async_grouped_lv_processes(socket) do
    assign_async(
      socket,
      :grouped_lv_processes,
      &DiscoveryQueries.fetch_grouped_lv_processes/0,
      reset: true
    )
  end
end
