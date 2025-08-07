defmodule LiveDebuggerRefactor.App.Debugger.Queries.LvProcess do
  @moduledoc """
  Queries for fetching the LvProcess.
  """

  alias LiveDebuggerRefactor.Structs.LvProcess

  @spec fetch_with_retries(pid()) :: LvProcess.t() | nil
  def fetch_with_retries(pid) when is_pid(pid) do
    with nil <- fetch_after(pid, 200),
         nil <- fetch_after(pid, 800) do
      fetch_after(pid, 1000)
    end
  end

  defp fetch_after(pid, milliseconds) when is_pid(pid) and is_integer(milliseconds) do
    Process.sleep(milliseconds)
    LvProcess.new(pid)
  end
end
