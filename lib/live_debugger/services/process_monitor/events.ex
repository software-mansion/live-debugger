defmodule LiveDebugger.Services.ProcessMonitor.Events do
  @moduledoc """
  Events produced by the ProcessMonitor service.
  """

  use LiveDebugger.Event

  alias LiveDebugger.CommonTypes

  defevent(LiveViewBorn, pid: pid(), transport_pid: pid())
  defevent(LiveViewDied, pid: pid(), transport_pid: pid())
  defevent(LiveComponentCreated, pid: pid(), cid: CommonTypes.cid())
  defevent(LiveComponentDeleted, pid: pid(), cid: CommonTypes.cid())
  defevent(DebuggerTerminated, debugger_pid: pid())
end
