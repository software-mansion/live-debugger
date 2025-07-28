defmodule LiveDebuggerRefactor.App.Settings.QueriesTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Fakes
  alias LiveDebuggerRefactor.App.Settings.Queries, as: SettingsQueries
  alias LiveDebuggerRefactor.MockAPISettingsStorage

  test "assign_settings/1 assigns settings to socket" do
    socket = Fakes.socket()

    expected_settings = %{dead_view_mode: false, another_setting: true}

    MockAPISettingsStorage
    |> expect(:get_all, fn -> expected_settings end)

    updated_socket = SettingsQueries.assign_settings(socket)

    assert updated_socket.assigns.settings == expected_settings
  end
end
