defmodule LiveDebugger.App.Discovery.Web.DiscoveryLive do
  @moduledoc """
  LiveView page for discovering all active LiveView sessions in the debugged application.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.Services.GarbageCollector.Events.TableTrimmed
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.API.LiveViewDiscovery
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
    |> assign(dead_liveviews?: true)
    |> assign_async_grouped_lv_processes()
    |> assign_async_dead_grouped_lv_processes()
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
      <div>
        <div class="min-h-92 flex-1 max-lg:p-8 pt-8 lg:w-[60rem] lg:m-auto">
          <DiscoveryComponents.header title="Active LiveViews" />

          <div class="mt-6">
            <.async_result :let={grouped_lv_processes} assign={@grouped_lv_processes}>
              <:loading><DiscoveryComponents.loading /></:loading>
              <:failed><DiscoveryComponents.failed /></:failed>
              <DiscoveryComponents.live_sessions grouped_lv_processes={grouped_lv_processes} />
            </.async_result>
          </div>
        </div>
        <div class="flex-1 max-lg:p-8 pt-8 lg:w-[60rem] lg:m-auto">
          <DiscoveryComponents.header title="Recently Died LiveViews" disabled?={!@dead_liveviews?}>
            <.toggle_switch
              id="dead-liveviews"
              checked={@dead_liveviews?}
              phx-click="toggle-dead-liveviews"
            />
          </DiscoveryComponents.header>

          <div :if={@dead_liveviews?} class="mt-6">
            <.async_result :let={dead_grouped_lv_processes} assign={@dead_grouped_lv_processes}>
              <:loading><DiscoveryComponents.loading /></:loading>
              <:failed><DiscoveryComponents.failed /></:failed>
              <DiscoveryComponents.live_sessions
                dead?={true}
                id="dead-sessions"
                grouped_lv_processes={dead_grouped_lv_processes}
              />
            </.async_result>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket
    |> assign_async_grouped_lv_processes()
    |> assign_async_dead_grouped_lv_processes()
    |> noreply()
  end

  def handle_event("toggle-dead-liveviews", _params, socket) do
    socket
    |> update(:dead_liveviews?, &(not &1))
    |> noreply()
  end

  def handle_event("remove-lv-process", %{"pid" => string_pid}, socket) do
    string_pid
    |> Parsers.string_to_pid()
    |> case do
      {:ok, pid} ->
        StatesStorage.delete!(pid)

        StatesStorage.get_all_states()
        |> Enum.filter(fn {_, %LvState{socket: socket}} -> socket.root_pid == pid end)
        |> Enum.each(fn {pid, _} -> StatesStorage.delete!(pid) end)

        socket

      :error ->
        socket
    end
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
    assign_async(
      socket,
      :dead_grouped_lv_processes,
      &fetch_dead_grouped_lv_processes/0
    )
  end

  defp fetch_dead_grouped_lv_processes() do
    dead_lv_processes =
      StatesStorage.get_all_states()
      |> Enum.filter(fn {pid, %LvState{}} -> not Process.alive?(pid) end)
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&(LvProcess.new(&1.pid, &1.socket) |> LvProcess.set_alive(false)))

    {:ok, %{dead_grouped_lv_processes: LiveViewDiscovery.group_lv_processes(dead_lv_processes)}}
  end
end
