defmodule LiveDebuggerRefactor.Services.ProcessMonitor.Events do
  @moduledoc """
  Events produced by the ProcessMonitor service.
  """

  use LiveDebuggerRefactor.Event

  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Structs.TreeNode

  defevent(LiveViewBorn, pid: pid())
  defevent(LiveViewDied, pid: pid())
  defevent(ComponentCreated, node_id: TreeNode.id())
  defevent(ComponentDeleted, node_id: TreeNode.id())
end
