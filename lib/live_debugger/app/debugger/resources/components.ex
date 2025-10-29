defmodule LiveDebugger.App.Debugger.Resources.Components do
  @moduledoc """
  Set of components for displaying resources information.
  """

  use LiveDebugger.App.Web, :component

  attr(:id, :string, required: true)

  def chart(assigns) do
    ~H"""
    <canvas id={@id} phx-hook="ChartHook"></canvas>
    """
  end
end
