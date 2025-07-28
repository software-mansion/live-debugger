defmodule LiveDebuggerRefactor.App.Settings.Queries do
  @moduledoc """
  Queries for `LiveDebuggerRefactor.App.Settings` context.
  """

  import Phoenix.Component

  alias LiveDebuggerRefactor.API.SettingsStorage

  def assign_settings(socket) do
    assign(socket, settings: SettingsStorage.get_all())
  end
end
