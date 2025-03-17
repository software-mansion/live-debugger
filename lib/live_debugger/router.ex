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

  scope "/", LiveDebugger do
    pipe_through([:dbg_browser])

    live("/", LiveViews.LiveViewsDashboardLive, :index)
    live("/transport_pid/:socket_id", LiveViews.ChannelDashboardLive, :find_transport_pid)
    live("/:transport_pid/:socket_id", LiveViews.ChannelDashboardLive, :show)
  end
end
