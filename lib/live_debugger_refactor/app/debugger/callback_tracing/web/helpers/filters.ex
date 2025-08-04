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
    |> Enum.map(&FiltersUtils.parse_callback/1)
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
        Map.put(acc, FiltersUtils.parse_callback(callback_fa), true)
      end)

    execution_time = %{
      "exec_time_max" => "",
      "exec_time_min" => "",
      "min_unit" => Parsers.time_units() |> List.first(),
      "max_unit" => Parsers.time_units() |> List.first()
    }

    %{functions: callbacks, execution_time: execution_time}
  end
end
