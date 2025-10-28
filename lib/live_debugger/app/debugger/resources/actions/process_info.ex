defmodule LiveDebugger.App.Debugger.Resources.Actions.ProcessInfo do
  @moduledoc """
  This module provides actions for process information.
  """

  alias LiveDebugger.App.Debugger.Resources.Structs.ProcessInfo
  alias LiveDebugger.API.System.ProcessInfo, as: ProcessInfoAPI

  @spec get_info(pid :: pid()) :: {:ok, ProcessInfo.t()} | {:error, term()}
  def get_info(pid) when is_pid(pid) do
    pid
    |> ProcessInfoAPI.get_info()
    |> case do
      {:ok, info} -> {:ok, ProcessInfo.new(info)}
      {:error, reason} -> {:error, reason}
    end
  end
end
