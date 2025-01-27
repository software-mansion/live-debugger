defmodule LiveDebugger.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :dbg_browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, html: {LiveDebugger.Layout, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through([:dbg_browser])

    import Phoenix.Router
    import Phoenix.LiveView.Router

    get("/css-:md5", LiveDebugger.Controllers.Assets, :css)
    get("/js-:md5", LiveDebugger.Controllers.Assets, :js)

    live("/", LiveDebugger.LiveViews.SessionsDashboard)
    live("/:socket_id", LiveDebugger.LiveViews.ChannelDashboard)
    live("/:socket_id/:node_id", LiveDebugger.LiveViews.ChannelDashboard)
  end
end
