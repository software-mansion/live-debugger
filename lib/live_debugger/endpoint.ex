defmodule LiveDebugger.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_debugger

  @signing_salt "wWTDRK9x"

  @session_options [
    store: :cookie,
    key: "_live_debugger",
    signing_salt: @signing_salt,
    same_site: "Lax",
    # 14 days
    max_age: 14 * 24 * 60 * 60
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: true,
    longpoll: true
  )

  plug(Plug.Static, from: {:live_debugger, "priv/static"}, at: "/assets/phoenix")

  plug(Plug.Static,
    from: {:live_debugger_live_view, "priv/static"},
    at: "/assets/phoenix_live_view"
  )

  plug(Plug.Session, @session_options)

  plug(Plug.RequestId)
  plug(LiveDebugger.Router)
end
