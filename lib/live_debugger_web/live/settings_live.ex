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
        <Navbar.return_link return_link={RoutesHelper.live_views_dashboard()} />
        <Navbar.live_debugger_logo />
      </Navbar.navbar>
      <div class="flex-1 max-lg:p-8 pt-8 lg:w-[60rem] lg:m-auto">
        <div class="flex items-center justify-between">
          <.h1>Settings</.h1>
        </div>

        <%!-- Upper section --%>
        <div class="mt-6 bg-surface-0-bg rounded shadow-custom border border-default-border">
          <%!-- Appearance --%>
          <div class="p-6">
            <p class="font-semibold	mb-3">Appearance</p>
            <div class="flex gap-2">
              <.dark_mode_button />
              <.light_mode_button />
            </div>
          </div>
          <%!-- Checkboxes --%>
          <div class="p-6 border-t border-default-border flex flex-col gap-3">
            <.settings_switch
              label="Enable DeadView mode"
              description="When enabled, LiveDebugger won't redirect to new LiveView after page redirect or reload, allowing you to browse assigns and traces of dead LiveViews."
              checked={false}
              phx-click="update"
              phx-value-setting="deadview_mode"
            />

            <.settings_switch
              label="Enable global tracing"
              description="Enabling this feature may have a negative impact on application performance."
              checked={false}
              phx-click="update"
              phx-value-setting="global_tracing"
            />

            <.settings_switch
              label="Refresh tracing on reload"
              description="Enabling this feature may have a negative impact on application performance."
              checked={false}
              phx-click="update"
              phx-value-setting="refresh_tracing_on_reload"
            />
          </div>
        </div>

        <%!-- Lower section --%>
        <div class="mt-6 bg-surface-0-bg rounded shadow-custom border border-default-border">
          <%!-- Restart button --%>
          <div class="p-6 flex flex-col md:flex-row justify-between md:items-center gap-4">
            <div class="flex flex-col gap-1">
              <p class="font-semibold">Restart LiveDebugger</p>
              <p class="text-secondary-text">
                Use this option if LiveDebugger appears to stop responding or not working properly.
              </p>
            </div>
            <.button variant="secondary" phx-click="restart">Restart&nbsp;LiveDebugger</.button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("update", %{"setting" => _setting}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("restart", _, socket) do
    {:noreply, socket}
  end

  attr(:label, :string, required: true)
  attr(:description, :string, required: true)
  attr(:checked, :boolean, default: false)
  attr(:rest, :global)

  defp settings_switch(assigns) do
    ~H"""
    <div class="flex items-center">
      <.toggle_switch checked={@checked} wrapper_class="pr-3 py-0" {@rest} />
      <div class="flex flex-col gap-0.5">
        <p class="font-semibold"><%= @label %></p>
        <p class="text-secondary-text"><%= @description %></p>
      </div>
    </div>
    """
  end

  defp dark_mode_button(assigns) do
    ~H"""
    <.mode_button
      id="dark-mode-switch"
      icon="icon-moon"
      text="Dark"
      class="dark:hidden text-button-secondary-content bg-button-secondary-bg hover:bg-button-secondary-bg-hover border border-default-border"
      phx-hook="ToggleTheme"
    />
    <.mode_button
      icon="icon-moon"
      text="Dark"
      class="hidden dark:flex text-button-primary-content bg-button-primary-bg"
    />
    """
  end

  defp light_mode_button(assigns) do
    ~H"""
    <.mode_button
      id="light-mode-switch"
      icon="icon-sun"
      text="Light"
      class="hidden dark:flex text-button-secondary-content bg-button-secondary-bg hover:bg-button-secondary-bg-hover border border-default-border"
      phx-hook="ToggleTheme"
    />
    <.mode_button
      icon="icon-sun"
      text="Light"
      class="dark:hidden text-button-primary-content bg-button-primary-bg"
    />
    """
  end

  attr(:icon, :string, required: true)
  attr(:text, :string, required: true)
  attr(:class, :string, default: "")
  attr(:rest, :global)

  defp mode_button(assigns) do
    ~H"""
    <button
      class={[
        "flex items-center justify-center gap-2 py-2 px-4 rounded",
        @class
      ]}
      {@rest}
    >
      <.icon name={@icon} class="w-5 h-5" />
      <p><%= @text %></p>
    </button>
    """
  end
end
