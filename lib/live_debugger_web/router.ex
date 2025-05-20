defmodule LiveDebuggerWeb.Router do
  use Phoenix.Router, helpers: false

  import Phoenix.LiveView.Router

  pipeline :dbg_browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {LiveDebuggerWeb.Layout, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(LiveDebuggerWeb.Plugs.AllowIframe)
  end

  pipeline :public do
    plug(:accepts, ["json"])
  end

  scope "/window", LiveDebuggerWeb do
    pipe_through([:public])

    get("/:window_id", SocketDiscoveryController, :update_window)
  end

  scope "/", LiveDebuggerWeb do
    pipe_through([:dbg_browser])

    get("/redirect/:socket_id", SocketDiscoveryController, :redirect)

    live("/error/:error", ErrorLive)
    live("/pid/:pid", ChannelDashboardLive)
    live("/", LiveViewsDashboardLive)
  end
end
