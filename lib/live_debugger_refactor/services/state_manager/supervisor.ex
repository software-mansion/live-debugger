defmodule LiveDebuggerRefactor.Services.StateManager.Supervisor do
  @moduledoc """
  Supervisor for `StateManager` service.
  """

  use Supervisor

  alias LiveDebuggerRefactor.Services.StateManager.GenServer.StateManager

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [StateManager]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
