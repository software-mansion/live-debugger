defmodule LiveDebuggerRefactor.App.Debugger.Queries.LvProcess do
  @moduledoc """
  Queries for fetching the LvProcess.
  """

  alias LiveDebuggerRefactor.App.Debugger.Queries.State, as: StateQueries
  alias LiveDebuggerRefactor.API.LiveViewDiscovery
  alias LiveDebuggerRefactor.Structs.LvProcess

  @spec get_successor_with_retries(LvProcess.t()) :: LvProcess.t() | nil
  def get_successor_with_retries(lv_process) do
    retries = [50, 100, 200]

    fetch_with_retries(fn -> LiveViewDiscovery.successor_lv_process(lv_process) end, retries)
  end

  @doc """
  Same as `get_lv_process/1` but it uses timeout and retries to fetch the LvProcess.
  """
  @spec get_lv_process_with_retries(pid()) :: LvProcess.t() | nil
  def get_lv_process_with_retries(pid) when is_pid(pid) do
    fetch_with_retries(fn -> get_lv_process(pid) end, [50, 100, 200])
  end

  @spec get_lv_process(pid()) :: LvProcess.t() | nil
  def get_lv_process(pid) when is_pid(pid) do
    case StateQueries.get_socket(pid) do
      {:error, _} -> nil
      {:ok, socket} -> LvProcess.new(pid, socket)
    end
  end

  defp fetch_with_retries(function, retries) when is_function(function) and is_list(retries) do
    Enum.reduce_while(retries, nil, fn timeout, nil ->
      Process.sleep(timeout)

      case function.() do
        nil -> {:cont, nil}
        result -> {:halt, result}
      end
    end)
  end
end
