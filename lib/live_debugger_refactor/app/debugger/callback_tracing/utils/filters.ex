defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Utils.Filters do
  @moduledoc """
  Set of useful functions for Filters in CallbackTracing.
  """

  import LiveDebuggerRefactor.App.Debugger.Structs.TreeNode.Guards

  alias LiveDebuggerRefactor.App.Debugger.Structs.TreeNode
  alias LiveDebuggerRefactor.Utils.Callbacks, as: UtilsCallbacks
  alias LiveDebuggerRefactor.App.Utils.Parsers

  @doc """
  Returns a list of callbacks' `{function, arity}` tuples for the given node_id's type.
  Returns all callbacks if the node_id is nil.
  """
  @spec node_callbacks(TreeNode.id() | nil) :: [UtilsCallbacks.fa()]
  def node_callbacks(node_id) when is_nil(node_id) or is_node_id(node_id) do
    type = if node_id, do: TreeNode.type(node_id), else: :global

    case type do
      :live_view -> UtilsCallbacks.live_view_callbacks()
      :live_component -> UtilsCallbacks.live_component_callbacks()
      :global -> UtilsCallbacks.all_callbacks()
    end
  end

  @doc """
  Parses a callback tuple into a string.
  """
  @spec parse_callback(UtilsCallbacks.fa()) :: String.t()
  def parse_callback({function, arity}) do
    "#{function}/#{arity}"
  end

  @doc """
  Check if form's `params` and given `filters` have any differences in the given `group_name` group.
  """
  @spec group_changed?(params :: map(), filters :: map(), group_name :: atom()) :: boolean()
  def group_changed?(params, filters, group_name)
      when is_map(params) and is_map_key(filters, group_name) do
    group_filters =
      Map.fetch!(filters, group_name)

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
  Validates execution time params.
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
    |> validate_execution_time_value_is_integer(:exec_time_min, min_time)
    |> validate_execution_time_value_is_integer(:exec_time_max, max_time)
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

  defp validate_execution_time_value_is_integer(errors, field, value) do
    if String.contains?(value, [",", "."]) do
      Keyword.put(errors, field, "must be an integer")
    else
      errors
    end
  end

  defp validate_execution_time_min_is_less_than_max(
         [],
         min_time,
         max_time,
         min_time_unit,
         max_time_unit
       ) do
    if min_time != "" and max_time != "" and
         apply_unit_factor(min_time, min_time_unit) >
           apply_unit_factor(max_time, max_time_unit) do
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
    String.to_integer(value)
    |> Parsers.time_to_microseconds(unit)
  end
end
