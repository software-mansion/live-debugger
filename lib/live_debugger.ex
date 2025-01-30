defmodule LiveDebugger do
  use Application

  def start(_type, _args) do
    check_origin = Application.get_env(:live_debugger, :check_origin, false)
    pubsub_server = Application.get_env(:live_debugger, :pubsub_server, LiveDebugger.PubSub)

    children = [
      {Phoenix.PubSub, name: LiveDebugger.PubSub},
      {LiveDebugger.Endpoint,
       [
         check_origin: check_origin,
         pubsub_server: pubsub_server
       ]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
