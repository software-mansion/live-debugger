defmodule LiveDebuggerWeb.SettingsLive do
  @moduledoc """
  LiveView for the settings page.
  """

  use LiveDebuggerWeb, :live_view

  alias LiveDebugger.GenServers.CallbackTracingServer
  alias LiveDebugger.GenServers.SettingsServer
  alias LiveDebuggerWeb.Components.Navbar
  alias LiveDebuggerWeb.Helpers.RoutesHelper

  @impl true
  def handle_params(params, _url, socket) do
    socket
    |> assign(:return_to, params["return_to"])
    |> assign_settings()
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 min-w-[25rem] grid grid-rows-[auto_1fr]">
      <Navbar.navbar class="flex">
        <Navbar.return_link return_link={@return_to || RoutesHelper.live_views_dashboard()} />
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
              id="dead-view-mode-switch"
              label="Enable DeadView mode"
              description="When enabled, LiveDebugger won't redirect to new LiveView after page redirect or reload, allowing you to browse assigns and traces of dead LiveViews."
              checked={@settings[:dead_view_mode]}
              phx-click="update"
              phx-value-setting="dead_view_mode"
            />

            <.settings_switch
              id="tracing-update-on-reload-switch"
              label="Refresh tracing after recompilation"
              description="Tracing in LiveDebugger may be interrupted when modules are recompiled. With this option enabled, LiveDebugger will refresh tracing after project recompilation. It may have a negative impact on application performance."
              checked={@settings[:tracing_update_on_code_reload]}
              phx-click="update"
              phx-value-setting="tracing_update_on_code_reload"
            />
          </div>
        </div>

        <%!-- Lower section --%>
        <div class="mt-6 bg-surface-0-bg rounded shadow-custom border border-default-border">
          <%!-- Refresh tracing button --%>
          <div class="p-6 flex flex-col md:flex-row justify-between md:items-center gap-4">
            <div class="flex flex-col gap-1">
              <p class="font-semibold">Refresh LiveDebugger Tracing</p>
              <p class="text-secondary-text">
                Manually refresh traced modules and callbacks. Use this when you don't see traces from your application.
              </p>
            </div>
            <.button variant="secondary" phx-click="restart">Refresh&nbsp;Tracing</.button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("update", %{"setting" => setting}, socket) do
    setting = String.to_existing_atom(setting)

    new_setting_value = not socket.assigns.settings[setting]

    SettingsServer.save(setting, new_setting_value)

    settings = Map.put(socket.assigns.settings, setting, new_setting_value)

    socket
    |> assign(:settings, settings)
    |> noreply()
  end

  @impl true
  def handle_event("restart", _, socket) do
    CallbackTracingServer.update_traced_modules()
    {:noreply, socket}
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:description, :string, required: true)
  attr(:checked, :boolean, default: false)
  attr(:rest, :global)

  defp settings_switch(assigns) do
    ~H"""
    <div class="flex items-center">
      <.toggle_switch id={@id} checked={@checked} wrapper_class="pr-3 py-0" {@rest} />
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
      disabled
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
      disabled
      class="dark:hidden text-button-primary-content bg-button-primary-bg"
    />
    """
  end

  attr(:icon, :string, required: true)
  attr(:text, :string, required: true)
  attr(:class, :string, default: "")
  attr(:rest, :global, include: ~w(disabled))

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

  defp assign_settings(socket) do
    assign(socket, :settings, SettingsServer.get_all())
  end
end
