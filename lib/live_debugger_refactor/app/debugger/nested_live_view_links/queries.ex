defmodule LiveDebuggerRefactor.App.Debugger.NestedLiveViewLinks.Queries do
  @moduledoc """
  Queries for `LiveDebuggerRefactor.App.Debugger.NestedLiveViewLinks` context.
  """

  alias LiveDebuggerRefactor.API.LiveViewDebug
  alias LiveDebuggerRefactor.Structs.LvState
  alias LiveDebuggerRefactor.API.StatesStorage

  @doc """
  Checks if the given `child_pid` is a child LiveView process of the `parent_pid`.
  """
  @spec child_lv_process?(parent_pid :: pid(), child_pid :: pid()) :: boolean()
  def child_lv_process?(parent_pid, child_pid) do
    case fetch_socket(child_pid) do
      {:error, _} -> false
      {:ok, %{parent_pid: nil}} -> false
      {:ok, %{parent_pid: ^parent_pid}} -> true
      {:ok, socket} -> child_lv_process?(parent_pid, socket.parent_pid)
    end
  end

  defp fetch_socket(pid) do
    case StatesStorage.get!(pid) do
      %LvState{socket: socket} -> {:ok, socket}
      nil -> LiveViewDebug.socket(pid)
    end
  end
end
