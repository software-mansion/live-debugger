defmodule LiveDebuggerRefactor.Services.ProcessMonitor.Events do
  @moduledoc """
  Events produced by the ProcessMonitor service.
  """

  use LiveDebuggerRefactor.Event

  alias LiveDebuggerRefactor.CommonTypes

  defevent(LiveViewBorn, pid: pid())
  defevent(LiveViewDied, pid: pid())
  defevent(LiveComponentCreated, cid: CommonTypes.cid())
  defevent(LiveComponentDeleted, cid: CommonTypes.cid())
end
