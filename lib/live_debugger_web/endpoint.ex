defmodule LiveDebuggerWeb.Endpoint do
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

  plug(Plug.Static, from: {:phoenix, "priv/static"}, at: "/assets/phoenix")
  plug(Plug.Static, from: {:phoenix_live_view, "priv/static"}, at: "/assets/phoenix_live_view")

  cond do
    LiveDebugger.Env.dev?() ->
      plug(Plug.Static,
        at: "/assets/live_debugger",
        from: {:live_debugger, "priv/static/dev"},
        gzip: false
      )

      socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
      plug(Phoenix.LiveReloader)
      plug(Phoenix.CodeReloader)

    LiveDebugger.Env.test?() ->
      plug(Plug.Static,
        at: "/assets/live_debugger",
        from: {:live_debugger, "priv/static/dev"},
        gzip: false
      )

    true ->
      plug(Plug.Static,
        at: "/assets/live_debugger",
        from: {:live_debugger, "priv/static"},
        gzip: false
      )
  end

  plug(Plug.Session, @session_options)

  plug(Plug.RequestId)
  plug(LiveDebuggerWeb.Router)
end
