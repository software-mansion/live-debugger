defmodule LiveDebugger.App.Debugger.Resources.Components.Chart do
  @moduledoc """
  This module delivers a chart component for displaying resources information.
  Chart uses the `ChartHook` that uses the "Chart.js" library to render the chart.

  You can use the `append_new_data/2` function to append new data to the chart dynamically.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Resources.Structs.ProcessInfo
  alias Phoenix.LiveView.Socket

  @keys_to_display ~w(memory total_heap_size heap_size stack_size reductions message_queue_len)a

  attr(:id, :string, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def render(assigns) do
    ~H"""
    <div class={@class} phx-update="ignore" id={"#{@id}-wrapper"}>
      <canvas id={@id} phx-hook="ChartHook"></canvas>
    </div>
    """
  end

  @spec append_new_data(Socket.t(), ProcessInfo.t()) :: Socket.t()
  def append_new_data(socket, %ProcessInfo{} = process_info) do
    data = Map.take(process_info, @keys_to_display)

    Phoenix.LiveView.push_event(socket, "update-chart", data)
  end
end
