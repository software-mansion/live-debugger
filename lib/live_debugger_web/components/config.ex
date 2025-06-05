defmodule LiveDebuggerWeb.Components.Config do
  @moduledoc """
  Renders the LiveDebugger config meta tag and the browser features script.
  It is meant to be injected to the debugged application layout.
  """

  use Phoenix.Component

  attr(:url, :string, required: true)
  attr(:assets_url, :string, required: true)
  attr(:browser_features?, :boolean, default: true)
  attr(:debug_button?, :boolean, default: true)
  attr(:highlighting?, :boolean, default: true)
  attr(:version, :string, default: nil)
  attr(:devtools_allow_redirects, :boolean, default: false)

  def live_debugger_tags(assigns) do
    ~H"""
    <meta
      name="live-debugger-config"
      url={@url}
      version={@version}
      debug-button={@debug_button?}
      highlighting={@highlighting?}
      devtools-allow-redirects={@devtools_allow_redirects}
    />
    <%= if @browser_features? do %>
      <script src={@assets_url}>
      </script>
    <% end %>
    """
  end
end
