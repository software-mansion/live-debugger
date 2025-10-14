defmodule LiveDebugger.App.Web.Router do
  @moduledoc """
  Router for the LiveDebugger Web application.
  """

  use Phoenix.Router, helpers: false

  import Phoenix.LiveView.Router

  alias LiveDebugger.App

  pipeline :dbg_browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {App.Web.Layout, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(App.Web.Plugs.AllowIframe)
  end

  scope "/", App do
    pipe_through([:dbg_browser])

    get("/redirect/:socket_id", Controllers.SocketDiscoveryController, :redirect)

    live("/error/:error", Web.ErrorLive)
    live("/pid/:pid", Debugger.Web.DebuggerLive, :node_inspector)
    live("/pid/:pid/global_traces", Debugger.Web.DebuggerLive, :global_traces)
    live("/settings", Settings.Web.SettingsLive)
    live("/", Discovery.Web.DiscoveryLive)
  end
end
