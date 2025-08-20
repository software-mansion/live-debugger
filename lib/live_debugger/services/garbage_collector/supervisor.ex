defmodule LiveDebugger.Services.GarbageCollector.Supervisor do
  @moduledoc """
  Supervisor for GarbageCollector service.
  """

  use Supervisor

  alias LiveDebugger.Services.GarbageCollector.GenServers.GarbageCollector
  alias LiveDebugger.Services.GarbageCollector.GenServers.TableWatcher

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {TableWatcher, []},
      {GarbageCollector, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
