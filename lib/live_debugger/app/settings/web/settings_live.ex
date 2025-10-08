defmodule LiveDebugger.App.Settings.Web.SettingsLive do
  @moduledoc """
  LiveView page for changing application settings.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.App.Events.UserChangedSettings
  alias LiveDebugger.API.SettingsStorage
  alias LiveDebugger.App.Settings.Actions, as: SettingsActions
  alias LiveDebugger.App.Settings.Web.Components, as: SettingsComponents
  alias LiveDebugger.App.Web.Components.Navbar, as: NavbarComponents
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.UserRefreshedTrace

  @available_settings SettingsStorage.available_settings() |> Enum.map(&Atom.to_string/1)

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket) do
      Bus.receive_events!()
    end

    socket
    |> assign(return_to: params["return_to"])
    |> assign(settings: SettingsStorage.get_all())
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 min-w-[25rem] grid grid-rows-[auto_1fr]">
      <NavbarComponents.navbar class="flex pl-2">
        <NavbarComponents.return_link return_link={@return_to || RoutesHelper.discovery()} />
        <NavbarComponents.live_debugger_logo />
      </NavbarComponents.navbar>
      <div class="flex-1 max-lg:p-8 pt-8 lg:w-[60rem] lg:m-auto">
        <div class="flex items-center justify-between">
          <.h1>Settings</.h1>
        </div>

        <%!-- Upper section --%>
        <div class="mt-6 bg-surface-0-bg rounded shadow-custom border border-default-border">
          <%!-- Appearance --%>
          <div class="p-6">
            <p class="font-semibold mb-3">Appearance</p>
            <div class="flex gap-2">
              <SettingsComponents.dark_mode_button />
              <SettingsComponents.light_mode_button />
            </div>
          </div>
          <%!-- Checkboxes --%>
          <div class="p-6 border-t border-default-border flex flex-col gap-3">
            <SettingsComponents.settings_switch
              id="dead-view-mode-switch"
              label="Enable DeadView mode"
              description="When enabled, LiveDebugger won't redirect to new LiveView after page redirect or reload, allowing you to browse assigns and traces of dead LiveViews."
              checked={@settings[:dead_view_mode]}
              phx-click="update"
              phx-value-setting="dead_view_mode"
            />

            <SettingsComponents.settings_switch
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
  def handle_event("restart", _params, socket) do
    Bus.broadcast_event!(%UserRefreshedTrace{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("update", %{"setting" => setting}, socket)
      when setting in @available_settings do
    setting = String.to_existing_atom(setting)

    socket.assigns.settings
    |> SettingsActions.update_settings!(setting, not socket.assigns.settings[setting])
    |> case do
      {:ok, new_settings} ->
        assign(socket, settings: new_settings)

      {:error, _} ->
        push_flash(socket, :error, "Failed to update setting")
    end
    |> noreply()
  end

  @impl true
  def handle_info(%UserChangedSettings{key: setting, value: value, from: from_pid}, socket)
      when from_pid != socket.root_pid do
    socket
    |> assign(settings: Map.put(socket.assigns.settings, setting, value))
    |> noreply()
  end

  def handle_info(_, socket), do: noreply(socket)
end
