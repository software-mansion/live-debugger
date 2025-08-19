defmodule LiveDebugger.Services.ClientCommunicator.Supervisor do
  @moduledoc """
  Supervisor for `ClientCommunicator` service.
  """

  use Supervisor

  alias LiveDebugger.Services.ClientCommunicator.GenServers.ClientCommunicator

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [ClientCommunicator]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
