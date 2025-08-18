defmodule LiveDebugger.Services do
  @moduledoc """
  Module for managing services.
  """

  @spec append_services_children(children :: list()) :: list()
  def append_services_children(children) do
    children ++
      [
        {LiveDebugger.Services.CallbackTracer.Supervisor, []},
        {LiveDebugger.Services.GarbageCollector.Supervisor, []},
        {LiveDebugger.Services.ProcessMonitor.Supervisor, []},
        {LiveDebugger.Services.ClientCommunicator.Supervisor, []},
        {LiveDebugger.Services.SuccessorDiscoverer.Supervisor, []}
      ]
  end
end
