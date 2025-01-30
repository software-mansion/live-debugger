defmodule LiveDebugger.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_debugger

  @session_options [
    store: :cookie,
    key: "_live_debugger",
    signing_salt: "lvd_debug",
    same_site: "Lax",
    # 14 days
    max_age: 14 * 24 * 60 * 60
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: true,
    longpoll: true
  )

  plug(Plug.Session, @session_options)

  plug(Plug.RequestId)
  plug(LiveDebugger.Router)
end
