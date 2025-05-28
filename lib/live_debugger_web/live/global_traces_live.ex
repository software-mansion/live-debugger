defmodule LiveDebuggerWeb.GlobalTracesLive do
  use LiveDebuggerWeb, :live_view
  use LiveDebuggerWeb.Hooks.LinkedView

  alias LiveDebuggerWeb.Components.Navbar
  alias LiveDebuggerWeb.Components.NavigationMenu
  alias LiveDebuggerWeb.Helpers.RoutesHelper
  alias LiveDebugger.Utils.Parsers

  @impl true
  def render(assigns) do
    ~H"""
    <div id="channel-dashboard" class="w-screen h-screen grid grid-rows-[auto_1fr]">
      <Navbar.navbar class="grid grid-cols-[auto_auto_1fr_auto] pl-2 lg:pr-4">
        <Navbar.return_link
          return_link={get_return_link(@lv_process, @in_iframe?)}
          class="hidden sm:block"
        />
        <NavigationMenu.dropdown
          return_link={get_return_link(@lv_process, @in_iframe?)}
          current_url={@url}
          class="sm:hidden"
        />
        <Navbar.live_debugger_logo_icon />
        <div
          :if={not @lv_process.ok?}
          class="animate-pulse w-36 bg-surface-1-bg rounded text-surface-1-bg"
        >
          Loading...
        </div>
        <Navbar.connected
          :if={@lv_process.ok?}
          id="navbar-connected"
          connected?={@lv_process.result.alive?}
          pid={Parsers.pid_to_string(@lv_process.result.pid)}
        />
        <div class="flex items-center gap-2">
          <Navbar.settings_button return_to={@url} />
          <span class="h-5 border-r border-default-border lg:hidden"></span>
          <.nav_icon class="flex lg:hidden" icon="icon-panel-right" />
        </div>
      </Navbar.navbar>

      <div class="flex overflow-hidden">
        <NavigationMenu.sidebar class="hidden sm:flex" current_url={@url} />

        <.async_result :let={_lv_process} assign={@lv_process}>
          <:loading>
            <div class="m-auto flex items-center justify-center">
              <.spinner size="xl" />
            </div>
          </:loading>
        </.async_result>
      </div>
    </div>
    """
  end

  defp get_return_link(lv_process, in_iframe?) do
    cond do
      not in_iframe? ->
        RoutesHelper.live_views_dashboard()

      not lv_process.ok? ->
        nil

      in_iframe? ->
        RoutesHelper.window_dashboard(lv_process.result.transport_pid)
    end
  end
end
