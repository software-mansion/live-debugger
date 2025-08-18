defmodule LiveDebuggerRefactor.Services do
  @moduledoc """
  Module for managing services.
  """

  @spec append_services_children(children :: list()) :: list()
  def append_services_children(children) do
    children ++
      [
        {LiveDebuggerRefactor.Services.CallbackTracer.Supervisor, []},
        {LiveDebuggerRefactor.Services.GarbageCollector.Supervisor, []},
        {LiveDebuggerRefactor.Services.ProcessMonitor.Supervisor, []},
        {LiveDebuggerRefactor.Services.ClientCommunicator.Supervisor, []},
        {LiveDebuggerRefactor.Services.SuccessorDiscoverer.Supervisor, []}
      ]
  end
end
