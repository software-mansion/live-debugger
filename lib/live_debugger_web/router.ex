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

  scope "/", LiveDebuggerWeb do
    pipe_through([:dbg_browser])

    get("/redirect/:socket_id", SocketDiscoveryController, :redirect)

    live("/error/:error", ErrorLive)
    live("/pid/:pid/global_traces", LvProcessLive, :global_traces)
    live("/pid/:pid", LvProcessLive, :node_inspector)
    live("/transport_pid/:transport_pid", WindowDashboardLive)

    live("/settings", SettingsLive)
    live("/", LiveViewsDashboardLive)
  end
end
