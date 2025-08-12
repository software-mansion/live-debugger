defmodule LiveDebuggerRefactor.App.Debugger.Queries.LvProcess do
  @moduledoc """
  Queries for fetching the LvProcess.
  """

  alias LiveDebuggerRefactor.App.Debugger.Queries.State, as: StateQueries
  alias LiveDebuggerRefactor.Structs.LvProcess

  @doc """
  Same as `get_lv_process/1` but it uses timeout and retries to fetch the LvProcess.
  """
  @spec get_lv_process_with_retries(pid()) :: LvProcess.t() | nil
  def get_lv_process_with_retries(pid) when is_pid(pid) do
    fetch_after = fn timeout ->
      Process.sleep(timeout)
      get_lv_process(pid)
    end

    with nil <- fetch_after.(50),
         nil <- fetch_after.(100) do
      fetch_after.(200)
    end
  end

  @spec get_lv_process(pid()) :: LvProcess.t() | nil
  def get_lv_process(pid) when is_pid(pid) do
    case StateQueries.get_socket(pid) do
      {:error, _} -> nil
      {:ok, socket} -> LvProcess.new(pid, socket)
    end
  end
end
