defmodule LiveDebugger.Services.ProcessMonitor.Supervisor do
  @moduledoc """
  Supervisor for ProcessMonitor service.
  """
  alias LiveDebugger.Services.ProcessMonitor.GenServers.ProcessMonitor

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {ProcessMonitor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
