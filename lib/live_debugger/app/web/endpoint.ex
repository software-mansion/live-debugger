defmodule LiveDebugger.App.Web.Endpoint do
  @moduledoc """
  `Phoenix.Endpoint` module for LiveDebugger
  """

  use Phoenix.Endpoint, otp_app: :live_debugger

  alias LiveDebugger.App.Web

  @session_options [
    store: :cookie,
    key: "_live_debugger",
    signing_salt: "lvd_debug",
    same_site: "Lax",
    # 14 days
    max_age: 14 * 24 * 60 * 60
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: true, longpoll: true)
  socket("/client", LiveDebugger.Client.Socket, websocket: true, longpoll: false)

  plug(Plug.Static, from: {:phoenix, "priv/static"}, at: "/assets/phoenix")
  plug(Plug.Static, from: {:phoenix_live_view, "priv/static"}, at: "/assets/phoenix_live_view")

  if LiveDebugger.Env.dev?() do
    plug(Plug.Static,
      at: "/assets/live_debugger",
      from: {:live_debugger, "priv/static/dev"},
      gzip: false
    )

    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  else
    plug(Plug.Static,
      at: "/assets/live_debugger",
      from: {:live_debugger, "priv/static"},
      gzip: false
    )
  end

  plug(Plug.Session, @session_options)
  plug(Plug.RequestId)
  plug(Web.Router)
end
