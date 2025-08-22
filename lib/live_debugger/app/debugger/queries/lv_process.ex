defmodule LiveDebugger.App.Debugger.Queries.LvProcess do
  @moduledoc """
  Queries for fetching the LvProcess.
  """

  @retries_timeouts [50, 100, 200]

  alias LiveDebugger.App.Debugger.Queries.State, as: StateQueries
  alias LiveDebugger.Structs.LvProcess

  @doc """
  Same as `get_lv_process/1` but it uses timeout and retries to fetch the LvProcess.
  """
  @spec get_lv_process_with_retries(pid()) :: LvProcess.t() | nil
  def get_lv_process_with_retries(pid) when is_pid(pid) do
    fetch_with_retries(fn -> get_lv_process(pid) end)
  end

  @spec get_lv_process(pid()) :: LvProcess.t() | nil
  def get_lv_process(pid) when is_pid(pid) do
    case StateQueries.get_socket(pid) do
      {:error, _} -> nil
      {:ok, socket} -> LvProcess.new(pid, socket)
    end
  end

  defp fetch_with_retries(function) when is_function(function) do
    Enum.reduce_while(@retries_timeouts, nil, fn timeout, nil ->
      Process.sleep(timeout)

      case function.() do
        nil -> {:cont, nil}
        result -> {:halt, result}
      end
    end)
  end
end
