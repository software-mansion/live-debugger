defmodule LiveDebuggerDev.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_debugger_dev_app

  @signing_salt "ll+Leuc4"

  @session_options [
    store: :cookie,
    key: "_live_debugger_dev_app",
    signing_salt: @signing_salt,
    same_site: "Lax",
    # 14 days
    max_age: 14 * 24 * 60 * 60
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: true,
    longpoll: true
  )

  plug(Plug.Static, from: {:phoenix, "priv/static"}, at: "/assets/phoenix")
  plug(Plug.Static, from: {:phoenix_live_view, "priv/static"}, at: "/assets/phoenix_live_view")

  socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)

  plug(Phoenix.LiveReloader)
  plug(Phoenix.CodeReloader)

  plug(Plug.Session, @session_options)

  plug(Plug.RequestId)
  plug(LiveDebuggerDev.Router)
end
