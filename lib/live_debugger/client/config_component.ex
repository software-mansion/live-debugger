defmodule LiveDebugger.Client.ConfigComponent do
  @moduledoc """
  Renders the LiveDebugger config meta tag and the browser features script.
  It is meant to be injected to the debugged application layout.
  """

  use Phoenix.Component

  attr(:url, :string, required: true)
  attr(:js_url, :string, required: true)
  attr(:phoenix_url, :string, required: true)
  attr(:browser_features?, :boolean, default: true)
  attr(:version, :string, default: nil)
  attr(:debug_button?, :boolean, default: true)
  attr(:e2e?, :boolean, default: false)

  def live_debugger_tags(assigns) do
    ~H"""
    <%= if @e2e? do %>
      <meta
        name="live-debugger-config"
        url={@url}
        version={@version}
        debug-button={@debug_button?}
        e2e="true"
      />
    <% else %>
      <meta name="live-debugger-config" url={@url} version={@version} debug-button={@debug_button?} />
    <% end %>
    <%= if @browser_features? do %>
      <script src={@js_url}>
      </script>
      <script src={@phoenix_url}>
      </script>
    <% end %>
    """
  end
end
