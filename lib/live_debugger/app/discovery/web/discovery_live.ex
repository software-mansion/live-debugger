defmodule LiveDebugger.App.Discovery.Web.DiscoveryLive do
  @moduledoc """
  LiveView page for discovering all active and dead LiveView sessions in the debugged application.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.App.Web.Components.Navbar, as: NavbarComponents
  alias LiveDebugger.App.Discovery.Web.LiveComponents.ActiveLiveViews
  alias LiveDebugger.App.Discovery.Web.LiveComponents.DeadLiveViews

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.UserChangedSettings
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.Services.GarbageCollector.Events.TableTrimmed

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bus.receive_events!()
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex-1 min-w-[25rem] grid grid-rows-[auto_1fr]">
      <NavbarComponents.navbar class="flex justify-between">
        <NavbarComponents.live_debugger_logo />
        <NavbarComponents.settings_button return_to={@url} />
      </NavbarComponents.navbar>
      <div class="h-full flex flex-col">
        <.live_component module={ActiveLiveViews} id="active-live-views" />
        <.live_component module={DeadLiveViews} id="dead-live-views" />
      </div>
    </div>
    """
  end

  @impl true
  def handle_info(%LiveViewBorn{}, socket) do
    ActiveLiveViews.refresh("active-live-views")
    {:noreply, socket}
  end

  def handle_info(%LiveViewDied{}, socket) do
    ActiveLiveViews.refresh("active-live-views")
    DeadLiveViews.refresh("dead-live-views")
    {:noreply, socket}
  end

  def handle_info(%TableTrimmed{}, socket) do
    DeadLiveViews.refresh("dead-live-views")
    {:noreply, socket}
  end

  def handle_info(%UserChangedSettings{key: :dead_liveviews, value: value}, socket) do
    send_update(DeadLiveViews, id: "dead-live-views", dead_liveviews?: value)
    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
