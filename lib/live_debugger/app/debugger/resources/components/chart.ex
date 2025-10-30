defmodule LiveDebugger.App.Debugger.Resources.Components.Chart do
  @moduledoc """
  Set of components for displaying resources information.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Resources.Structs.ProcessInfo
  alias Phoenix.LiveView.Socket

  attr(:id, :string, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def render(assigns) do
    ~H"""
    <div class={@class} phx-update="ignore" id={"#{@id}-wrapper"}>
      <canvas id={@id} phx-hook="ChartHook"></canvas>
    </div>
    """
  end

  @spec append_new_data(Socket.t(), %ProcessInfo{}) :: Socket.t()
  def append_new_data(socket, %ProcessInfo{} = process_info) do
    data =
      Map.take(process_info, [
        :memory,
        :total_heap_size,
        :heap_size,
        :stack_size,
        :reductions,
        :message_queue_len
      ])

    Phoenix.LiveView.push_event(socket, "update-chart", data)
  end
end
