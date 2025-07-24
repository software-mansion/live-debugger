defmodule LiveDebuggerRefactor.App.Debugger.Web.DebuggerLive do
  @moduledoc false

  use LiveDebuggerRefactor.App.Web, :live_view

  alias LiveDebuggerRefactor.App.Debugger.ComponentsTree.Web, as: ComponentsTreeWeb

  def render(assigns) do
    ~H"""
    <div id="debugger-live">
      <h1>TEMPORARY DEBUGGER LIVE</h1>
      <ComponentsTreeWeb.components_tree_live id="components-tree" socket={@socket} />
    </div>
    """
  end
end
