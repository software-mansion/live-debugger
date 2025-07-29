defmodule LiveDebuggerRefactor.App.Settings.Actions do
  @moduledoc """
  Action for `LiveDebuggerRefactor.App.Settings` context.
  """

  alias LiveDebuggerRefactor.API.SettingsStorage

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.App.Events.UserChangedSettings

  @spec update_settings!(
          settings :: %{atom() => any()},
          setting :: atom(),
          value :: any()
        ) :: %{atom() => any()}
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
