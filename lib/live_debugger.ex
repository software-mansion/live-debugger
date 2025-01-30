defmodule LiveDebugger do
  use Application

  def start(_type, _args) do
    secret_key_base = Application.fetch_env!(:live_debugger, :secret_key_base)
    signing_salt = Application.fetch_env!(:live_debugger, :signing_salt)
    http = Application.fetch_env!(:live_debugger, :http)

    check_origin = Application.get_env(:live_debugger, :check_origin, false)
    pubsub_server = Application.get_env(:live_debugger, :pubsub_server, LiveDebugger.PubSub)
    adapter = Application.get_env(:live_debugger, :adapter, Bandit.PhoenixAdapter)

    config = [
      secret_key_base: secret_key_base,
      live_view: [signing_salt: signing_salt],
      http: [port: http],
      check_origin: check_origin,
      pubsub_server: pubsub_server,
      adapter: adapter
    ]

    children = [
      {Phoenix.PubSub, name: LiveDebugger.PubSub},
      {LiveDebugger.Endpoint, config}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
