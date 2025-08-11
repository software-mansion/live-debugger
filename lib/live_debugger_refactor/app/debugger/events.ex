defmodule LiveDebuggerRefactor.App.Debugger.Events do
  @moduledoc """
  Events broadcasted by the Debugger context.
  """

  use LiveDebuggerRefactor.Event

  alias LiveDebuggerRefactor.App.Debugger.Structs.TreeNode

  defevent(NodeIdParamChanged, node_id: TreeNode.id())
end
