defmodule LiveDebugger.App.Debugger.Queries.LvProcess do
  @moduledoc """
  Queries for fetching the LvProcess.
  """

  alias LiveDebugger.App.Debugger.Queries.State, as: StateQueries
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.API.WindowsStorage
  alias LiveDebugger.API.LiveViewDiscovery

  @doc """
  Same as `get_lv_process_with_retries/1` but also resolves and sets `window_id` on the LvProcess.
  Uses timeout and retries until the process and window id are available.
  """
  @spec get_lv_process_with_retries_and_window_id(pid()) :: LvProcess.t() | nil
  def get_lv_process_with_retries_and_window_id(pid) when is_pid(pid) do
    retries_timeouts = [100, 200, 400, 800]

    Enum.reduce_while(retries_timeouts, nil, fn timeout, nil ->
      Process.sleep(timeout)

      with %LvProcess{} = lv_process <- get_lv_process(pid),
           lv_processes = LiveViewDiscovery.debugged_lv_processes(),
           fingerprint when is_binary(fingerprint) <-
             WindowsStorage.create_fingerprint(lv_processes),
           window_id when is_binary(window_id) <-
             WindowsStorage.get_window_id!(fingerprint) do
        {:halt, LvProcess.set_window_id(lv_process, window_id)}
      else
        _ -> {:cont, nil}
      end
    end)
  end

  @doc """
  Same as `get_lv_process/1` but it uses timeout and retries to fetch the LvProcess.
  """
  @spec get_lv_process_with_retries(pid()) :: LvProcess.t() | nil
  def get_lv_process_with_retries(pid) when is_pid(pid) do
    retries_timeouts = [50, 100, 200]

    Enum.reduce_while(retries_timeouts, nil, fn timeout, nil ->
      Process.sleep(timeout)

      case get_lv_process(pid) do
        nil -> {:cont, nil}
        result -> {:halt, result}
      end
    end)
  end

  @spec get_lv_process(pid()) :: LvProcess.t() | nil
  def get_lv_process(pid) when is_pid(pid) do
    case StateQueries.get_socket(pid) do
      {:error, _} ->
        nil

      {:ok, socket} ->
        pid
        |> LvProcess.new(socket)
        |> LvProcess.set_alive(Process.alive?(pid))
    end
  end
end
