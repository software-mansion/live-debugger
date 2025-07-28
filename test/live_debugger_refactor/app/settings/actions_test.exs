defmodule LiveDebuggerRefactor.App.Settings.ActionsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Mox

  alias LiveDebuggerRefactor.App.Settings.Actions, as: SettingsActions
  alias LiveDebuggerRefactor.Fakes
  alias LiveDebuggerRefactor.MockAPISettingsStorage

  alias LiveDebuggerRefactor.MockBus
  alias LiveDebuggerRefactor.App.Events.UserChangedSettings

  describe "update_settings!/3" do
    test "successfully updates settings" do
      socket = assign(Fakes.socket(), settings: %{dead_view_mode: false})
      setting = :dead_view_mode
      value = true

      MockAPISettingsStorage
      |> expect(:save, fn ^setting, ^value -> :ok end)

      MockBus
      |> expect(:broadcast_event!, fn %UserChangedSettings{key: ^setting, value: ^value} ->
        :ok
      end)

      updated_socket = SettingsActions.update_settings!(socket, setting, value)

      assert updated_socket.assigns.settings[setting] == value
    end

    test "fails to update settings" do
      socket = assign(Fakes.socket(), settings: %{dead_view_mode: false})
      setting = :dead_view_mode
      value = false

      MockAPISettingsStorage
      |> expect(:save, fn ^setting, ^value -> {:error, :failed} end)

      updated_socket = SettingsActions.update_settings!(socket, setting, value)

      assert updated_socket.assigns.settings[setting] == false
    end
  end
end
