defmodule LiveDebugger.App.Debugger.NestedLiveViewLinks.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.Debugger.NestedLiveViewLinks` context.
  """

  alias LiveDebugger.App.Debugger.Queries.State, as: StateQueries

  @doc """
  Checks if the given `child_pid` is a child LiveView process of the `parent_pid`.
  """
  @spec child_lv_process?(parent_pid :: pid(), child_pid :: pid()) :: boolean()
  def child_lv_process?(parent_pid, child_pid) do
    case StateQueries.get_socket(child_pid) do
      {:error, _} -> false
      {:ok, %{parent_pid: nil}} -> false
      {:ok, %{parent_pid: ^parent_pid}} -> true
      {:ok, socket} -> child_lv_process?(parent_pid, socket.parent_pid)
    end
  end
end
