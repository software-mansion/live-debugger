defmodule LiveDebuggerRefactor.App.Discovery.Web.WindowDiscoveryLive do
  @moduledoc """
  This view is a variant of the LiveViews dashboard, but it is used to display LiveViews in the given window.
  It cannot be accessed from the browser directly, but:
  - it is used when there are many LiveViews in the same window, and we cannot find a single successor.
  - in case of extension this replaces the LiveViews dashboard, since extension works in a single window.
  """

  use LiveDebuggerRefactor.App.Web, :live_view

  alias LiveDebuggerRefactor.App.Utils.Parsers
  alias LiveDebuggerRefactor.App.Web.Helpers.Routes, as: RoutesHelper

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebuggerRefactor.App.Discovery.Web.Components, as: DiscoveryComponents
  alias LiveDebuggerRefactor.App.Web.Components.Navbar, as: NavbarComponents

  @impl true
  def mount(%{"transport_pid" => string_transport_pid}, _session, socket) do
    string_transport_pid
    |> Parsers.string_to_pid()
    |> case do
      {:ok, _transport_pid} ->
        socket
        |> assign(:grouped_lv_processes, AsyncResult.ok(%{}))

      :error ->
        push_navigate(socket, to: RoutesHelper.error("invalid_pid"))
    end
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="window-dashboard" class="flex-1 min-w-[25rem] grid grid-rows-[auto_1fr]">
      <NavbarComponents.navbar class={"grid  #{if @in_iframe?, do: "grid-cols-[auto_1fr_auto] ", else: "grid-cols-[auto_auto_1fr_auto] pl-2"} "}>
        <NavbarComponents.return_link
          class={if @in_iframe?, do: "hidden", else: ""}
          return_link={RoutesHelper.discovery()}
        />
        <NavbarComponents.live_debugger_logo />
        <NavbarComponents.fill />
        <NavbarComponents.settings_button return_to={@url} />
      </NavbarComponents.navbar>
      <div class="flex-1 max-lg:p-8 pt-8 lg:w-[60rem] lg:m-auto">
        <div class="flex items-center justify-between">
          <.h1>Active LiveViews in a single window</.h1>
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
              <.alert with_icon heading="Error fetching active LiveViews">
                Check logs for more
              </.alert>
            </:failed>
            <div id="live-sessions" class="flex flex-col gap-4">
              <%= if Enum.empty?(grouped_lv_processes)  do %>
                <div class="p-4 bg-surface-0-bg rounded shadow-custom border border-default-border">
                  <p class="text-secondary-text text-center">No active LiveViews</p>
                </div>
              <% else %>
                <DiscoveryComponents.tab_group
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
    |> push_flash("Not implemented yet")
    |> noreply()
  end
end
