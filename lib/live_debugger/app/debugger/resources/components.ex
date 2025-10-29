defmodule LiveDebugger.App.Debugger.Resources.Components do
  @moduledoc """
  Set of components for displaying resources information.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Resources.Structs.ProcessInfo

  attr(:id, :string, required: true)
  attr(:process_info, ProcessInfo, required: true)
  attr(:selected_key, :atom, default: :memory)

  def chart(assigns) do
    ~H"""
    <canvas
      id={@id}
      phx-hook="ChartHook"
      data-process-info-value={Map.get(@process_info, @selected_key)}
      data-process-info-key={@selected_key}
    >
    </canvas>
    """
  end
end
