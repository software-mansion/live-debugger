defmodule LiveDebugger.Supervisor do
  @moduledoc false

  use Supervisor

  @pubsub_server Application.compile_env(:live_debugger, :pubsub_server, LiveDebugger.PubSub)
  @check_origin Application.compile_env(:live_debugger, :check_origin, false)

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      {Phoenix.PubSub, name: LiveDebugger.PubSub},
      {LiveDebugger.Endpoint,
       [
         pubsub_server: @pubsub_server,
         check_origin: @check_origin
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
