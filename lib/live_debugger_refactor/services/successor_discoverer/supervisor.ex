defmodule LiveDebuggerRefactor.Services.SuccessorDiscoverer.Supervisor do
  @moduledoc """
  Supervisor for `SuccessorDiscoverer` service.
  """

  use Supervisor
  alias LiveDebuggerRefactor.Services.SuccessorDiscoverer.GenServers.SuccessorDiscoverer

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [SuccessorDiscoverer]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
