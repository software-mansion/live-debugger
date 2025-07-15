defmodule LiveDebuggerRefactor.Services.ProcessMonitor.Events do
  @moduledoc """
  Events produced by the ProcessMonitor service.
  """

  use LiveDebuggerRefactor.Event

  alias LiveDebugger.CommonTypes

  defevent(LiveViewBorn, pid: pid())
  defevent(LiveViewDied, pid: pid())
  defevent(ComponentCreated, node_id: CommonTypes.cid())
  defevent(ComponentDeleted, node_id: CommonTypes.cid())
end
