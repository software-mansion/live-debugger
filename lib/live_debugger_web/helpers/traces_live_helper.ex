defmodule LiveDebuggerWeb.Helpers.TracesLiveHelper do
  require Logger

  import Phoenix.Component

  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks

  def assign_default_filters(socket) do
    assign(socket, :default_filters, default_filters(socket.assigns.node_id))
  end

  def reset_current_filters(socket) do
    assign(socket, :current_filters, socket.assigns.default_filters)
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
        {:exec_time_min, ""},
        {:min_unit, ""},
        {:max_unit, ""}
      ]
    }
  end

  def get_active_functions(socket) do
    socket.assigns.current_filters.functions
    |> Enum.filter(fn {_, active?} -> active? end)
    |> Enum.map(fn {function, _} -> function end)
  end

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

  def log_async_error(operation, reason) do
    Logger.error(
      "LiveDebugger encountered unexpected error while #{operation}: #{inspect(reason)}"
    )
  end
end
