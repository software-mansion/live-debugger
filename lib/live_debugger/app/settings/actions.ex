defmodule LiveDebugger.App.Settings.Actions do
  @moduledoc """
  Action for `LiveDebugger.App.Settings` context.
  """

  alias LiveDebugger.API.SettingsStorage

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.UserChangedSettings

  @spec update_settings!(
          settings :: %{atom() => any()},
          setting :: atom(),
          value :: any()
        ) :: {:ok, %{atom() => any()}} | {:error, term()}
  def update_settings!(settings, setting, value) do
    case SettingsStorage.save(setting, value) do
      :ok ->
        Bus.broadcast_event!(%UserChangedSettings{key: setting, value: value, from: self()})

        {:ok, Map.put(settings, setting, value)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
