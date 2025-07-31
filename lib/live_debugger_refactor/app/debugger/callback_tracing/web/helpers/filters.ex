defmodule LiveDebuggerRefactor.CallbackTracing.Helpers.Filters do
  @moduledoc """
  Helper functions for FiltersForm.
  """

  import LiveDebuggerRefactor.App.Debugger.TreeNode.Guards

  alias LiveDebuggerRefactor.App.Debugger.TreeNode
  alias LiveDebuggerRefactor.Utils.Callbacks, as: UtilsCallbacks

  @doc """
  Returns a list of formatted callbacks for the given node id.
  If the node id is nil, returns all callbacks.
  """
  @spec get_callbacks(TreeNode.type() | nil) :: [String.t()]
  def get_callbacks(nil) do
    UtilsCallbacks.all_callbacks()
    |> Enum.map(&parse_callback/1)
  end

  def get_callbacks(node_id) when is_node_id(node_id) do
    node_id
    |> TreeNode.type()
    |> case do
      :live_view -> UtilsCallbacks.live_view_callbacks()
      :live_component -> UtilsCallbacks.live_component_callbacks()
    end
    |> Enum.map(&parse_callback/1)
  end

  defp parse_callback({function, arity}) do
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
    Enum.flat_map(filters, fn {_group, value} -> value end)
    |> Enum.any?(fn {key, value} ->
      value != params[key]
    end)
  end
end
