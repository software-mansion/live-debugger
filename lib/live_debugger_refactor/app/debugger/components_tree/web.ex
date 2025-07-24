defmodule LiveDebuggerRefactor.App.Debugger.ComponentsTree.Web do
  @moduledoc """
  Functions responsible for accessing `LiveDebuggerRefactor.App.Debugger.ComponentsTree.Web` context.
  """
  use LiveDebuggerRefactor.App.Web, :component

  @doc """
  Renders the ComponentsTreeLive as nested LiveView component.
  """
  attr(:id, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true)

  def components_tree_live(assigns) do
    assigns = assign(assigns, :session, %{})

    ~H"""
    <%= live_render(@socket, __MODULE__.ComponentsTreeLive, id: @id, session: @session) %>
    """
  end
end
