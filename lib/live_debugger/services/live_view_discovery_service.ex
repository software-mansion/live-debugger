defmodule LiveDebugger.Services.LiveViewDiscoveryService do
  @moduledoc """
  This module provides functions that discovers LiveView processes in the debugged application.
  """
  alias LiveDebugger.Services.System.ProcessService
  alias LiveDebugger.Structs.LvProcess

  @doc """
  Returns all debugged LvProcesses.
  """
  @spec debugged_lv_processes() :: [LvProcess.t()]
  def debugged_lv_processes() do
    lv_processes()
    |> Enum.reject(& &1.debugger?)
  end

  @doc """
  Returns all LiveDebugger's LvProcesses.
  """
  @spec debugger_lv_processes() :: [LvProcess.t()]
  def debugger_lv_processes() do
    lv_processes()
    |> Enum.filter(& &1.debugger?)
  end

  @doc """
  Returns LvProcess associated the given `socket_id`.
  """
  @spec lv_process(socket_id :: String.t()) :: LvProcess.t() | nil
  def lv_process(socket_id) do
    debugged_lv_processes()
    |> Enum.find(&(&1.socket_id == socket_id))
  end

  @doc """
  Finds potential successor LvProcess based on module when websocket connection breaks and new one is created.
  This is a common scenario when user recompiles code or refreshes the page
  """
  @spec successor_lv_processes(module :: module()) :: [LvProcess.t()]
  def successor_lv_processes(module) do
    lv_processes()
    |> Enum.filter(fn lv_process ->
      not lv_process.debugger? and lv_process.module == module
    end)
  end

  @doc """
  Returns all LiveView processes.
  """
  @spec lv_processes() :: [LvProcess.t()]
  def lv_processes() do
    ProcessService.list()
    |> Enum.reject(&(&1 == self()))
    |> Enum.map(&{&1, ProcessService.initial_call(&1)})
    |> Enum.filter(fn {_, initial_call} -> liveview?(initial_call) end)
    |> Enum.map(fn {pid, _} -> LvProcess.new(pid) end)
    |> Enum.reject(&is_nil/1)
  end

  @spec liveview?(initial_call :: mfa() | nil | {}) :: boolean()
  defp liveview?(initial_call) when initial_call not in [nil, {}] do
    elem(initial_call, 1) == :mount
  end

  defp liveview?(_), do: false
end
