defmodule LiveDebuggerWeb.Helpers.FiltersHelper do
  @moduledoc """
  This module provides a helper for traces filters.
  """

  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks
  alias LiveDebugger.Structs.TreeNode

  @type filters :: %{
          functions: keyword(boolean()),
          execution_time: keyword(String.t())
        }

  @spec calculate_selected_filters(filters(), filters()) :: integer()
  def calculate_selected_filters(current_filters, default_filters) do
    current_filters
    |> Map.keys()
    |> Enum.count(fn key -> current_filters[key] != default_filters[key] end)
  end

  @spec changed_filter?(atom(), filters(), filters()) :: boolean()
  def changed_filter?(filter, current_filters, default_filters) do
    current_filters[filter] != default_filters[filter]
  end

  @spec default_filters(TreeNode.id()) :: filters()
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
        {:min_unit, Parsers.time_units() |> List.first()},
        {:max_unit, Parsers.time_units() |> List.first()}
      ]
    }
  end

  @spec get_active_functions(filters()) :: list(atom())
  def get_active_functions(current_filters) do
    current_filters.functions
    |> Enum.filter(fn {_, active?} -> active? end)
    |> Enum.map(fn {function, _} -> function end)
  end

  @spec get_execution_times(filters()) :: list(keyword())
  def get_execution_times(current_filters) do
    execution_time = current_filters.execution_time

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
