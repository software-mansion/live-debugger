defmodule LiveDebugger.App.Debugger.Resources.Components do
  @moduledoc """
  Set of components for displaying resources information.
  """

  use LiveDebugger.App.Web, :component

  attr(:id, :string, required: true)

  def chart(assigns) do
    ~H"""
    <div class="min-h-[30vh] lg:min-h-default" phx-update="ignore" id={"#{@id}-wrapper"}>
      <canvas id={@id} phx-hook="ChartHook"></canvas>
    </div>
    """
  end
end
