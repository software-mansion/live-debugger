defmodule LiveDebuggerWeb.Helpers.TracesLiveHelper do
  @moduledoc """
  This module provides helpers for the TracesLive and especially its hooks.
  Since these hooks get more complex and they touch different assigns and streams,
  this module was created to check if the assigns and streams are present in the socket.

  This way we can catch errors early and not have to debug them in the hooks.
  """

  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks
  alias LiveDebugger.Structs.TreeNode

  @doc """
  Checks if the assign is present in the socket.
  If not, it raises an error.
  """
  def check_assign!(socket, assign_name) do
    if Map.has_key?(socket.assigns, assign_name) do
      socket
    else
      raise "Assign #{assign_name} is required."
    end
  end

  @doc """
  Checks if the stream is present in the socket.
  If not, it raises an error.
  """
  def check_stream!(socket, stream_name) do
    if Map.has_key?(socket.assigns.streams, stream_name) do
      socket
    else
      raise "Stream #{stream_name} is required."
    end
  end

  @doc """
  Returns the default filters for the traces.
  """
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
