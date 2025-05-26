defmodule LiveDebuggerWeb.SettingsLive do
  @moduledoc """
  LiveView for the settings page.
  """

  use LiveDebuggerWeb, :live_view

  alias LiveDebuggerWeb.Components.Navbar
  alias LiveDebuggerWeb.Helpers.RoutesHelper

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 min-w-[25rem] grid grid-rows-[auto_1fr]">
      <Navbar.navbar class="flex">
        <Navbar.return_link link={RoutesHelper.live_views_dashboard()} />
        <Navbar.live_debugger_logo />
      </Navbar.navbar>
      <div class="flex-1 max-lg:p-8 pt-8 lg:w-[60rem] lg:m-auto">
        <div class="flex items-center justify-between">
          <.h1>Settings</.h1>
        </div>

        <div class="mt-6">
          <div id="live-sessions" class="flex flex-col gap-4">
            <div class="p-4 bg-surface-0-bg rounded shadow-custom border border-default-border"></div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
