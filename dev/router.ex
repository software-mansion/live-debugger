defmodule LiveDebuggerDev.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  import LiveDebugger.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, html: {LiveDebuggerDev.Layout, :root})
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through(:browser)

    live("/", LiveDebuggerDev.LiveViews.Main)
    live_debugger("/live_debug")
  end
end
