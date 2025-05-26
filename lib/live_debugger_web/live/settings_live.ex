defmodule LiveDebuggerWeb.SettingsLive do
  @moduledoc """
  LiveView for the settings page.
  """

  use LiveDebuggerWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Settings</h1>
    </div>
    """
  end
end
