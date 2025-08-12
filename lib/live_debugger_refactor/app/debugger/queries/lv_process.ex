defmodule LiveDebuggerRefactor.App.Debugger.Queries.LvProcess do
  @moduledoc """
  Queries for fetching the LvProcess.
  """

  alias LiveDebuggerRefactor.App.Debugger.Queries.State, as: StateQueries
  alias LiveDebuggerRefactor.Structs.LvProcess

  @spec get_lv_process(pid()) :: LvProcess.t() | nil
  def get_lv_process(pid) when is_pid(pid) do
    case StateQueries.get_socket(pid) do
      {:error, _} -> nil
      {:ok, socket} -> LvProcess.new(pid, socket)
    end
  end
end
