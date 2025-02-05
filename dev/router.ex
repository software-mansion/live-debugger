defmodule LiveDebuggerDev.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, html: {LiveDebuggerDev.Layout, :root})
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through(:browser)

    live("/", LiveDebuggerDev.LiveViews.Main)
    live("/side", LiveDebuggerDev.LiveViews.Side)
    live("/embedded", LiveDebuggerDev.LiveViews.EmbeddedLiveViews)
  end
end
