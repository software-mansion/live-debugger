defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Utils.Filters do
  @moduledoc """
  Set of useful functions for Filters in CallbackTracing.
  """

  import LiveDebuggerRefactor.App.Debugger.Structs.TreeNode.Guards

  alias LiveDebuggerRefactor.App.Debugger.Structs.TreeNode
  alias LiveDebuggerRefactor.Utils.Callbacks, as: CallbacksUtils

  @doc """
  Calculates the number of selected filters, based on the default and current filters.
  """
  @spec count_selected_filters(default_filters :: map(), current_filters :: map()) ::
          integer()
  def count_selected_filters(default_filters, current_filters) do
    current_flattened_filters = flattened_filters(current_filters, [:min_unit, :max_unit])
    default_flattened_filters = flattened_filters(default_filters, [:min_unit, :max_unit])

    Enum.count(current_flattened_filters, fn {key, value} ->
      value != Map.get(default_flattened_filters, key)
    end)
  end

  @doc """
  Returns a list of callbacks' `{function, arity}` tuples for the given node_id's type.
  Returns all callbacks if the node_id is nil.
  """
  @spec node_callbacks(TreeNode.id() | nil) :: [CallbacksUtils.fa()]
  def node_callbacks(node_id) when is_nil(node_id) or is_node_id(node_id) do
    type = if node_id, do: TreeNode.type(node_id), else: :global

    case type do
      :live_view -> CallbacksUtils.live_view_callbacks()
      :live_component -> CallbacksUtils.live_component_callbacks()
      :global -> CallbacksUtils.all_callbacks()
    end
  end

  defp flattened_filters(filters, exclude_keys) when is_map(filters) and is_list(exclude_keys) do
    filters
    |> Enum.flat_map(fn {_group, value} -> value end)
    |> Enum.reject(fn {key, _value} -> key in exclude_keys end)
    |> Enum.into(%{})
  end
end
