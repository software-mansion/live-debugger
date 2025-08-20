defmodule LiveDebugger.Client.ConfigComponent do
  @moduledoc """
  Renders the LiveDebugger config meta tag and the browser features script.
  It is meant to be injected to the debugged application layout.
  """

  use Phoenix.Component

  attr(:url, :string, required: true)
  attr(:js_url, :string, required: true)
  attr(:css_url, :string, required: true)
  attr(:phoenix_url, :string, required: true)
  attr(:browser_features?, :boolean, default: true)
  attr(:debug_button?, :boolean, default: true)
  attr(:highlighting?, :boolean, default: true)
  attr(:version, :string, default: nil)

  def live_debugger_tags(assigns) do
    ~H"""
    <meta
      name="live-debugger-config"
      url={@url}
      version={@version}
      debug-button={@debug_button?}
      highlighting={@highlighting?}
    />
    <%= if @browser_features? do %>
      <script src={@js_url}>
      </script>
      <link rel="stylesheet" href={@css_url} />
      <script src={@phoenix_url}>
      </script>
    <% end %>
    """
  end
end
