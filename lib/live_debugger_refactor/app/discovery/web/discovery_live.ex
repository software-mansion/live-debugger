defmodule LiveDebuggerRefactor.App.Discovery.Web.DiscoveryLive do
  @moduledoc """
  LiveView page for discovering all active LiveView sessions in the debugged application.
  """

  use LiveDebuggerRefactor.App.Web, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebuggerRefactor.App.Discovery.Web.Components, as: DiscoveryComponents
  alias LiveDebuggerRefactor.App.Web.Components.Navbar, as: NavbarComponents

  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    socket
    |> assign(:grouped_lv_processes, AsyncResult.ok(%{}))
    |> noreply()
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
    |> push_flash("Not implemented yet")
    |> noreply()
  end
end
