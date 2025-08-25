defmodule LiveDebugger.App.Debugger.Events do
  @moduledoc """
  Events broadcasted by the Debugger context.
  """

  use LiveDebugger.Event

  alias LiveDebugger.App.Debugger.Structs.TreeNode

  defevent(NodeIdParamChanged, node_id: TreeNode.id(), debugger_pid: pid())
  defevent(DeadViewModeEntered, debugger_pid: pid())
end
