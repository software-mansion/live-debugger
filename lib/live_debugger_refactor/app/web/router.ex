defmodule LiveDebuggerRefactor.App.Web.Router do
  @moduledoc """
  Router for the LiveDebugger Web application.
  """

  use Phoenix.Router, helpers: false

  import Phoenix.LiveView.Router

  alias LiveDebuggerRefactor.App.Web

  pipeline :dbg_browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {Web.Layout, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Web.Plugs.AllowIframe)
  end

  scope "/", Web do
    pipe_through([:dbg_browser])
  end
end
