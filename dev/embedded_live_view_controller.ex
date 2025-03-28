defmodule LiveDebuggerDev.EmbeddedLiveViewController do
  use Phoenix.Controller, layouts: [html: {LiveDebuggerDev.Layout, :app}]

  import Phoenix.LiveView.Controller

  def embedded(conn, _params) do
    live_render(conn, LiveDebuggerDev.LiveViews.Nested, session: %{})
  end
end
