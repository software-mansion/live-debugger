defmodule LiveDebuggerRefactor.App.Settings.Queries do
  @moduledoc """
  Queries for `LiveDebuggerRefactor.App.Settings` context.
  """

  import Phoenix.Component

  alias LiveDebuggerRefactor.API.SettingsStorage

  @spec assign_settings(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def assign_settings(socket) do
    assign(socket, settings: SettingsStorage.get_all())
  end

  @spec available_settings() :: [String.t()]
  def available_settings() do
    SettingsStorage.available_settings()
    |> Enum.map(&Atom.to_string/1)
  end
end
