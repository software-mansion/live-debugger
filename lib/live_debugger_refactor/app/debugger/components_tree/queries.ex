defmodule LiveDebuggerRefactor.App.Debugger.ComponentsTree.Queries do
  @moduledoc """
  Queries for `LiveDebuggerRefactor.App.Debugger.ComponentsTree` context.
  """

  require Logger

  alias LiveDebuggerRefactor.API.StatesStorage
  alias LiveDebuggerRefactor.API.LiveViewDebug
  alias LiveDebuggerRefactor.App.Debugger.ComponentsTree.Utils, as: ComponentsTreeUtils

  @spec fetch_components_tree(pid()) :: {:ok, %{tree: map()}} | {:error, term()}
  def fetch_components_tree(lv_pid) when is_pid(lv_pid) do
    with {:ok, lv_state} <- fetch_state(lv_pid),
         {:ok, tree} <- ComponentsTreeUtils.build_tree(lv_state) do
      {:ok, %{tree: tree}}
    else
      error ->
        Logger.error("Failed to build tree: #{inspect(error)}")
        error
    end
  end

  defp fetch_state(pid) do
    case StatesStorage.get!(pid) do
      nil -> LiveViewDebug.liveview_state(pid)
      state -> {:ok, state}
    end
  end
end
