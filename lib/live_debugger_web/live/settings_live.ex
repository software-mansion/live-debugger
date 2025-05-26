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
          <div class="bg-surface-0-bg rounded shadow-custom border border-default-border">
            <div class="p-6">
              <p class="font-semibold	mb-3">Appearance</p>
              <div class="flex gap-2">
                <.dark_mode_button />
                <.light_mode_button />
              </div>
            </div>
            <div class="p-6 border-t border-default-border flex flex-col gap-3">
              <div class="flex items-center">
                <.toggle_switch checked={false} wrapper_class="pr-3 py-0" />
                <div class="flex flex-col gap-0.5">
                  <p class="font-semibold">Enable DeadView mode</p>
                  <p class="text-secondary-text">
                    TODO write description
                  </p>
                </div>
              </div>
              <div class="flex items-center">
                <.toggle_switch checked={false} wrapper_class="pr-3 py-0" />
                <div class="flex flex-col gap-0.5">
                  <p class="font-semibold">Enable global tracing</p>
                  <p class="text-secondary-text">
                    Enabling this feature may have a negative impact on application performance.
                  </p>
                </div>
              </div>
              <div class="flex items-center">
                <.toggle_switch checked={false} wrapper_class="pr-3 py-0" />
                <div class="flex flex-col gap-0.5">
                  <p class="font-semibold">Refresh tracing on reload</p>
                  <p class="text-secondary-text">
                    Enabling this feature may have a negative impact on application performance.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="mt-6">
          <div class="bg-surface-0-bg rounded shadow-custom border border-default-border">
            <div class="p-6">
              <div class="flex flex-col md:flex-row justify-between md:items-center gap-4">
                <div class="flex flex-col gap-1">
                  <p class="font-semibold">Restart LiveDebugger</p>
                  <p class="text-secondary-text">
                    Use this option if LiveDebugger appears to stop responding or not working properly.
                  </p>
                </div>
                <.button variant="secondary">Restart&nbsp;LiveDebugger</.button>
              </div>
            </div>
          </div>
        </div>
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
