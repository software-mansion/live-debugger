defmodule LiveDebugger.App.Debugger.ComponentsTree.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.Debugger.ComponentsTree` context.
  """

  require Logger

  alias LiveDebugger.App.Debugger.ComponentsTree.Utils, as: ComponentsTreeUtils
  alias LiveDebugger.App.Debugger.Queries.State, as: StateQueries

  @spec fetch_components_tree(pid()) :: {:ok, %{tree: map()}} | {:error, term()}
  def fetch_components_tree(lv_pid) when is_pid(lv_pid) do
    with {:ok, lv_state} <- StateQueries.get_lv_state(lv_pid),
         {:ok, tree} <- ComponentsTreeUtils.build_tree(lv_state) do
      {:ok, %{tree: tree}}
    else
      error ->
        Logger.error("Failed to build tree: #{inspect(error)}")
        error
    end
  end
end
