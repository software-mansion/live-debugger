defmodule LiveDebugger.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      {Phoenix.PubSub, name: LiveDebugger.PubSub},
      {LiveDebugger.Endpoint,
       [
         secret_key_base:
           Application.get_env(
             :live_debugger,
             :secret_key,
             "GUQyVZgm4m5cJVnTz17/nPc1AjiV3oe/XWAL9kPTsTSbJ8sA57g5fLvVy4ijKeJp"
           ),
         adapter: Application.get_env(:live_debugger, :adapter, Bandit.PhoenixAdapter),
         pubsub_server: Application.get_env(:live_debugger, :pubsub_server, LiveDebugger.PubSub),
         live_view: Application.get_env(:live_debugger, :live_view, signing_salt: "dsJ21r1Z"),
         check_origin: Application.get_env(:live_debugger, :check_origin, false)
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
