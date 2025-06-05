defmodule LiveDebuggerWeb.Live.Traces.Helpers do
  @moduledoc """
  This module contains the helpers for the traces live view.
  """

  require Logger

  import Phoenix.Component, only: [assign: 3]

  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks

  def assign_default_filters(socket) do
    node_id = Map.get(socket.assigns, :node_id)
    assign(socket, :default_filters, default_filters(node_id))
  end

  def assign_current_filters(socket, filters) do
    assign(socket, :current_filters, filters)
  end

  def assign_current_filters(socket) do
    reset_current_filters(socket)
  end

  def reset_current_filters(socket) do
    assign(socket, :current_filters, socket.assigns.default_filters)
  end

  def default_filters(node_id) do
    type = if node_id, do: TreeNode.type(node_id), else: :global

    functions =
      type
      |> case do
        :live_view -> UtilsCallbacks.live_view_callbacks()
        :live_component -> UtilsCallbacks.live_component_callbacks()
        :global -> UtilsCallbacks.all_callbacks()
      end
      |> Enum.map(fn {function, _} -> {function, true} end)

    %{
      functions: functions,
      execution_time: [
        {:exec_time_max, ""},
        {:exec_time_min, ""},
        {:min_unit, ""},
        {:max_unit, ""}
      ]
    }
  end

  @doc """
  Returns the active functions from the current filters.
  It uses the `current_filters` assigns to determine the active functions.
  """
  def get_active_functions(socket) do
    socket.assigns.current_filters.functions
    |> Enum.filter(fn {_, active?} -> active? end)
    |> Enum.map(fn {function, _} -> function end)
  end

  @doc """
  Returns the execution times from the current filters.
  It uses the `current_filters` assigns to determine the execution times.
  """
  def get_execution_times(socket) do
    execution_time = socket.assigns.current_filters.execution_time

    execution_time
    |> Enum.filter(fn {_, value} -> value not in ["" | Parsers.time_units()] end)
    |> Enum.map(fn {filter, value} -> {filter, String.to_integer(value)} end)
    |> Enum.map(fn {filter, value} ->
      case filter do
        :exec_time_min -> {filter, Parsers.time_to_microseconds(value, execution_time[:min_unit])}
        :exec_time_max -> {filter, Parsers.time_to_microseconds(value, execution_time[:max_unit])}
      end
    end)
  end
end
