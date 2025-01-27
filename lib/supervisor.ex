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
      LiveDebugger.Endpoint
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
