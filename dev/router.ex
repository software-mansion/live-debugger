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
    live("/nested", LiveDebuggerDev.LiveViews.Nested)
    live("/messages", LiveDebuggerDev.LiveViews.Messages)
    live("/embedded", LiveDebuggerDev.LiveViews.Embedded)
    live("/endless_crash_reload", LiveDebuggerDev.LiveViews.EndlessCrashReload)
    get("/embedded_in_controller", LiveDebuggerDev.EmbeddedLiveViewController, :embedded)
  end
end
