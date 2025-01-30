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

  plug(Plug.Static, at: "/assets", from: :live_debugger, gzip: false)

  plug(Plug.Session, @session_options)

  plug(Plug.RequestId)
  plug(LiveDebugger.Router)
end
