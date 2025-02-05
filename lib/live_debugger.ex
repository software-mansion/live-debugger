defmodule LiveDebugger do
  @moduledoc """
  Debugger for LiveView applications.
  """

  use Application

  def start(_type, _args) do
    Application.put_env(LiveDebugger, :debug_mode, true)

    check_origin = Application.get_env(:live_debugger, :check_origin, false)

    children = [
      {Phoenix.PubSub, name: LiveDebugger.PubSub},
      {LiveDebugger.Endpoint,
       [
         check_origin: check_origin,
         pubsub_server: LiveDebugger.PubSub
       ]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: LiveDebugger.Supervisor)
  end
end
