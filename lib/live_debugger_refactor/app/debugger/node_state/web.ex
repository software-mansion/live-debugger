defmodule LiveDebuggerRefactor.App.Debugger.NodeState.Web do
  @moduledoc """
  Functions responsible for accessing `LiveDebuggerRefactor.App.Debugger.NodeState.Web` context.
  """

  use LiveDebuggerRefactor.App.Web, :component

  alias LiveDebuggerRefactor.Structs.LvProcess

  @doc """
  Renders the `NodeStateLive` as a nested LiveView component.
  """
  attr(:id, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:params, :map, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "params" => assigns.params,
      "parent_pid" => self()
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: @class}
    ) %>
    """
  end
end
