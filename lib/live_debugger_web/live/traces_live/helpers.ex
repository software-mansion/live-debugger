defmodule LiveDebuggerWeb.Live.TracesLive.Helpers do
  @moduledoc """
  This module provides helpers for the TracesLive.
  """

  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks
  alias LiveDebugger.Structs.TreeNode

  def check_assign(socket, assign_name) do
    if Map.has_key?(socket.assigns, assign_name) do
      socket
    else
      raise "Assign #{assign_name} is required."
    end
  end

  def check_stream(socket, stream_name) do
    if Map.has_key?(socket.assigns.streams, stream_name) do
      socket
    else
      raise "Stream #{stream_name} is required."
    end
  end

  def default_filters(node_id) do
    functions =
      node_id
      |> TreeNode.type()
      |> case do
        :live_view -> UtilsCallbacks.live_view_callbacks()
        :live_component -> UtilsCallbacks.live_component_callbacks()
      end
      |> Enum.map(fn {function, _} -> {function, true} end)

    %{
      functions: functions,
      execution_time: [
        {:exec_time_max, ""},
        {:exec_time_min, ""}
      ]
    }
  end
end
