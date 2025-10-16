defmodule LiveDebugger.Services.ProcessMonitor.Supervisor do
  @moduledoc """
  Supervisor for ProcessMonitor service.
  """
  use Supervisor

  alias LiveDebugger.Services.ProcessMonitor.GenServers.DebuggedProcessesMonitor
  alias LiveDebugger.Services.ProcessMonitor.GenServers.DebuggerProcessesMonitor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {DebuggedProcessesMonitor, []},
      {DebuggerProcessesMonitor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
