defmodule LiveDebuggerRefactor.App.Settings.ActionsTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.App.Settings.Actions, as: SettingsActions
  alias LiveDebuggerRefactor.MockAPISettingsStorage

  alias LiveDebuggerRefactor.MockBus
  alias LiveDebuggerRefactor.App.Events.UserChangedSettings

  describe "update_settings!/3" do
    test "successfully updates settings" do
      settings = %{dead_view_mode: false, another_setting: true}
      setting = :dead_view_mode
      value = true

      MockAPISettingsStorage
      |> expect(:save, fn ^setting, ^value -> :ok end)

      MockBus
      |> expect(:broadcast_event!, fn %UserChangedSettings{key: ^setting, value: ^value} ->
        :ok
      end)

      assert {:ok, updated_settings} = SettingsActions.update_settings!(settings, setting, value)
      assert %{dead_view_mode: true, another_setting: true} = updated_settings
    end

    test "fails to update settings" do
      settings = %{dead_view_mode: false, another_setting: true}
      setting = :dead_view_mode
      value = true

      MockAPISettingsStorage
      |> expect(:save, fn ^setting, ^value -> {:error, :failed} end)

      assert {:error, :failed} = SettingsActions.update_settings!(settings, setting, value)
    end
  end
end
