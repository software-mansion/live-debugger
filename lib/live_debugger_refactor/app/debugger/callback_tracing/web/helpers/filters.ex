defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.Helpers.Filters do
  @moduledoc """
  Helpers for Filters in CallbackTracing.
  """

  import LiveDebuggerRefactor.App.Debugger.Structs.TreeNode.Guards

  alias LiveDebuggerRefactor.App.Debugger.CallbackTracing.Utils.Filters, as: FiltersUtils
  alias LiveDebuggerRefactor.App.Debugger.Structs.TreeNode
  alias LiveDebuggerRefactor.App.Utils.Parsers

  @doc """
  Returns a list of formatted callbacks for the given node id.
  If the node id is nil, returns all callbacks.
  """
  @spec get_callbacks(TreeNode.id() | nil) :: [String.t()]
  def get_callbacks(node_id) when is_nil(node_id) or is_node_id(node_id) do
    node_id
    |> FiltersUtils.node_callbacks()
    |> Enum.map(&parse_callback/1)
  end

  @doc """
  Returns the default filters for the given node id.
  Returns global filters if the node id is nil.
  """
  @spec default_filters(TreeNode.id() | nil) :: map()
  def default_filters(node_id) do
    callbacks =
      node_id
      |> FiltersUtils.node_callbacks()
      |> Enum.reduce(%{}, fn callback_fa, acc ->
        Map.put(acc, parse_callback(callback_fa), true)
      end)

    execution_time = %{
      "exec_time_max" => "",
      "exec_time_min" => "",
      "min_unit" => Parsers.time_units() |> List.first(),
      "max_unit" => Parsers.time_units() |> List.first()
    }

    %{functions: callbacks, execution_time: execution_time}
  end

  @doc """
  Check if form's `params` and given `filters` have any differences in the given `group_name` group.
  """
  @spec group_changed?(params :: map(), filters :: map(), group_name :: atom()) :: boolean()
  def group_changed?(params, filters, group_name)
      when is_map(params) and is_map_key(filters, group_name) do
    group_filters = Map.fetch!(filters, group_name)

    Enum.any?(group_filters, fn {key, value} ->
      value != params[key]
    end)
  end

  @doc """
  Check if form's `params` and given `filters` have any differences.
  """
  @spec filters_changed?(params :: map(), filters :: map()) :: boolean()
  def filters_changed?(params, filters) when is_map(params) and is_map(filters) do
    filters
    |> Enum.flat_map(fn {_group, value} -> value end)
    |> Enum.any?(fn {key, value} ->
      value != params[key]
    end)
  end

  @doc """
  Validates execution time params. It checks
  - if the min time is an integer
  - if the max time is an integer
  - if the min time is less than the max time
  """
  @spec validate_execution_time_params(execution_time_params :: %{String.t() => String.t()}) ::
          :ok | {:error, Keyword.t()}
  def validate_execution_time_params(%{
        "exec_time_min" => min_time,
        "exec_time_max" => max_time,
        "min_unit" => min_time_unit,
        "max_unit" => max_time_unit
      }) do
    []
    |> validate_is_integer(:exec_time_min, min_time)
    |> validate_is_integer(:exec_time_max, max_time)
    |> validate_execution_time_min_is_less_than_max(
      min_time,
      max_time,
      min_time_unit,
      max_time_unit
    )
    |> case do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  defp parse_callback({function, arity}) do
    "#{function}/#{arity}"
  end

  defp validate_is_integer(errors, field, value) do
    if String.contains?(value, [",", "."]) do
      Keyword.put(errors, field, "must be an integer")
    else
      errors
    end
  end

  defp validate_execution_time_min_is_less_than_max([], min_time, max_time, _, _)
       when min_time == "" or max_time == "" do
    []
  end

  defp validate_execution_time_min_is_less_than_max(
         [],
         min_time,
         max_time,
         min_time_unit,
         max_time_unit
       ) do
    min_time_value = apply_unit_factor(min_time, min_time_unit)
    max_time_value = apply_unit_factor(max_time, max_time_unit)

    if min_time_value > max_time_value do
      []
      |> Keyword.put(:exec_time_min, "min must be less than max")
      |> Keyword.put(:exec_time_max, "max must be greater than min")
    else
      []
    end
  end

  defp validate_execution_time_min_is_less_than_max(errors, _, _, _, _) do
    errors
  end

  defp apply_unit_factor(value, unit) do
    value
    |> String.to_integer()
    |> Parsers.time_to_microseconds(unit)
  end
end
