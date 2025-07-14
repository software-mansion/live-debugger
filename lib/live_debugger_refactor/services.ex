defmodule LiveDebuggerRefactor.Services do
  @moduledoc """
  Module for managing services.
  """

  def append_services_children(children) do
    children ++
      [
        {LiveDebuggerRefactor.Services.CallbackTracer.Supervisor, []},
        {LiveDebuggerRefactor.Services.GarbageCollector.Supervisor, []},
        {LiveDebuggerRefactor.Services.ProcessMonitor.Supervisor, []},
        {LiveDebuggerRefactor.Services.StateManager.Supervisor, []}
      ]
  end
end
