defmodule LiveDebugger do
  use Application

  def start(_type, _args) do
    check_origin = Application.get_env(:live_debugger, :check_origin, false)
    pubsub_server = Application.get_env(:live_debugger, :pubsub_server, LiveDebugger.PubSub)
    adapter = Application.get_env(:live_debugger, :adapter, Bandit.PhoenixAdapter)

    config = [
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
