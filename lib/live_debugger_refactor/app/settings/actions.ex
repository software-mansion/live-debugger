defmodule LiveDebuggerRefactor.App.Settings.Actions do
  @moduledoc """
  Action for `LiveDebuggerRefactor.App.Settings` context.
  """

  import LiveDebuggerRefactor.App.Web.Hooks.Flash, only: [push_flash: 2]
  import Phoenix.Component

  alias LiveDebuggerRefactor.API.SettingsStorage

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.App.Events.UserChangedSettings

  @spec update_settings!(
          socket :: Phoenix.LiveView.Socket.t(),
          setting :: atom(),
          value :: any()
        ) ::
          Phoenix.LiveView.Socket.t()
  def update_settings!(socket, setting, value) do
    settings = socket.assigns.settings

    case SettingsStorage.save(setting, value) do
      :ok ->
        Bus.broadcast_event!(%UserChangedSettings{key: setting, value: value})

        new_settings = Map.put(settings, setting, value)

        assign(socket, settings: new_settings)

      {:error, _} ->
        push_flash(socket, "Failed to update setting")
    end
  end
end
