defmodule LiveDebuggerRefactor.Services.ProcessMonitor.Events do
  @moduledoc """
  Events produced by the ProcessMonitor service.
  """

  use LiveDebuggerRefactor.Event

  alias LiveDebuggerRefactor.CommonTypes

  defevent(LiveViewBorn, pid: pid())
  defevent(LiveViewDied, pid: pid())
  defevent(LiveComponentCreated, pid: pid(), cid: CommonTypes.cid())
  defevent(LiveComponentDeleted, pid: pid(), cid: CommonTypes.cid())
end
