defmodule LiveDebugger.App.Discovery.Web.DiscoveryLive do
  @moduledoc """
  LiveView page for discovering all active LiveView sessions in the debugged application.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.App.Events.UserChangedSettings
  alias LiveDebugger.API.SettingsStorage
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.Services.GarbageCollector.Events.TableTrimmed
  alias LiveDebugger.App.Discovery.Web.Components, as: DiscoveryComponents
  alias LiveDebugger.App.Web.Components.Navbar, as: NavbarComponents
  alias LiveDebugger.App.Discovery.Queries, as: DiscoveryQueries
  alias LiveDebugger.App.Discovery.Actions, as: DiscoveryActions

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bus.receive_events!()
    end

    socket
    |> assign(dead_liveviews?: SettingsStorage.get(:dead_liveviews))
    |> assign_async_grouped_lv_processes()
    |> assign_async_dead_grouped_lv_processes()
    |> ok()
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
        <div class="h-3/7 overflow-hidden max-lg:p-8 pt-8 lg:w-[60rem] lg:mx-auto">
          <DiscoveryComponents.header title="Active LiveViews" refresh_event="refresh-active" />

          <div class="mt-6 max-h-92 overflow-y-auto">
            <.async_result :let={grouped_lv_processes} assign={@grouped_lv_processes}>
              <:loading><DiscoveryComponents.loading /></:loading>
              <:failed><DiscoveryComponents.failed /></:failed>
              <DiscoveryComponents.liveview_sessions
                id="live-sessions"
                grouped_lv_processes={grouped_lv_processes}
                empty_info="No active LiveViews"
              />
            </.async_result>
          </div>
        </div>
        <div class="h-3/7 max-lg:p-8 pt-8 lg:w-[60rem] lg:mx-auto">
          <DiscoveryComponents.header
            title="Recently Died LiveViews"
            refresh_event="refresh-dead"
            disabled?={!@dead_liveviews?}
          >
            <.toggle_switch
              id="dead-liveviews"
              checked={@dead_liveviews?}
              phx-click="toggle-dead-liveviews"
            />
          </DiscoveryComponents.header>

          <div :if={@dead_liveviews?}>
            <DiscoveryComponents.garbage_collection_warning />

            <div class="mt-6 max-h-92 overflow-y-auto">
              <.async_result :let={dead_grouped_lv_processes} assign={@dead_grouped_lv_processes}>
                <:loading><DiscoveryComponents.loading /></:loading>
                <:failed><DiscoveryComponents.failed /></:failed>
                <DiscoveryComponents.liveview_sessions
                  id="dead-sessions"
                  grouped_lv_processes={dead_grouped_lv_processes}
                  empty_info="No recently died LiveViews"
                  remove_event="remove-lv-state"
                />
              </.async_result>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("refresh-active", _params, socket) do
    socket
    |> assign_async_grouped_lv_processes()
    |> noreply()
  end

  def handle_event("refresh-dead", _params, socket) do
    socket
    |> assign_async_dead_grouped_lv_processes()
    |> noreply()
  end

  def handle_event("toggle-dead-liveviews", _params, socket) do
    new_value = !socket.assigns.dead_liveviews?

    DiscoveryActions.update_dead_liveviews_setting!(new_value)
    |> case do
      {:ok, true} ->
        socket
        |> assign(dead_liveviews?: true)
        |> assign_async_dead_grouped_lv_processes()

      {:ok, false} ->
        assign(socket, dead_liveviews?: false)

      {:error, _reason} ->
        push_flash(socket, :error, "Failed to update setting")
    end
    |> noreply()
  end

  def handle_event("remove-lv-state", %{"pid" => string_pid}, socket) do
    {:ok, pid} = Parsers.string_to_pid(string_pid)
    DiscoveryActions.remove_lv_process_state!(pid)

    socket
    |> assign_async_dead_grouped_lv_processes()
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
    |> assign_async_dead_grouped_lv_processes()
    |> noreply()
  end

  def handle_info(%TableTrimmed{}, socket) do
    socket
    |> assign_async_dead_grouped_lv_processes()
    |> noreply()
  end

  def handle_info(
        %UserChangedSettings{key: :dead_liveviews, value: value},
        socket
      ) do
    socket
    |> assign(dead_liveviews?: value)
    |> assign_async_dead_grouped_lv_processes()
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

  defp assign_async_dead_grouped_lv_processes(socket) do
    if socket.assigns.dead_liveviews? do
      assign_async(
        socket,
        :dead_grouped_lv_processes,
        &DiscoveryQueries.fetch_dead_grouped_lv_processes/0,
        reset: true
      )
    else
      socket
    end
  end
end
