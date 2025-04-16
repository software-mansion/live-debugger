defmodule LiveDebugger.Components.Config do
  @moduledoc """
  Renders the LiveDebugger config meta tag and the browser features script.
  It is meant to be injected to the debugged application layout.
  """

  use Phoenix.Component

  attr(:url, :string, required: true)
  attr(:assets_url, :string, required: true)
  attr(:browser_features?, :boolean, default: true)
  attr(:debug_button?, :boolean, default: true)

  def live_debugger_tags(assigns) do
    ~H"""
    <meta name="live-debugger-config" url={@url} debug-button={@debug_button?} />
    <%= if @browser_features? do %>
      <script src={@assets_url}>
      </script>
    <% end %>
    """
  end
end
