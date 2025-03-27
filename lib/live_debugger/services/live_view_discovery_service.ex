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
  Returns LvProcess associated the given `socket_id` and `transport_pid`.
  When only `socket_id` is provided, LvProcess with the given `socket_id` is returned.
  When more than one process is found, `nil` is returned.
  """
  @spec lv_process(socket_id :: String.t(), transport_pid :: pid() | nil) :: LvProcess.t() | nil
  def lv_process(socket_id, transport_pid \\ nil)

  def lv_process(socket_id, nil) when is_binary(socket_id) do
    debugged_lv_processes()
    |> Enum.filter(&(&1.socket_id == socket_id))
    |> case do
      [lv_process] -> lv_process
      _ -> nil
    end
  end

  def lv_process(socket_id, transport_pid) when is_pid(transport_pid) and is_binary(socket_id) do
    debugged_lv_processes()
    |> Enum.find(&(&1.socket_id == socket_id and &1.transport_pid == transport_pid))
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
  Groups LvProcesses by `transport_pid` and `root_pid`. To see map structure see examples.

  ## Examples

      iex> lv_processes = LiveDebugger.Services.LiveViewDiscoveryService.debugged_lv_processes()
      iex> LiveDebugger.Services.LiveViewDiscoveryService.group_lv_processes(lv_processes)
      %{
        #<0.123.0> => {
          %LiveDebugger.Structs.LvProcess{pid: #<0.223.0>} => [
            %LiveDebugger.Structs.LvProcess{root_pid: #<0.223.0>},
            %LiveDebugger.Structs.LvProcess{root_pid: #<0.223.0>}
          ],
        #<0.124.0> => [
          %LiveDebugger.Structs.LvProcess{pid: #<0.224.0>} => [
            %LiveDebugger.Structs.LvProcess{root_pid: #<0.224.0>},
            %LiveDebugger.Structs.LvProcess{root_pid: #<0.224.0>}
          ]
        }
      }


  """
  @spec group_lv_processes(lv_processes :: [LvProcess.t()]) :: %{
          pid() => %{LvProcess.t() => [LvProcess.t()]}
        }
  def group_lv_processes(lv_processes) do
    lv_processes
    |> Enum.group_by(& &1.transport_pid)
    |> Enum.map(fn {tpid, groupped_by_tpid} ->
      groupped_by_tpid
      |> Enum.group_by(& &1.root_pid)
      |> Enum.map(fn {rpid, groupped_by_rpid} ->
        root_lv_process = Enum.find(groupped_by_rpid, &(&1.root_pid == rpid))
        rest = Enum.reject(groupped_by_rpid, &(&1.pid == rpid))

        {root_lv_process, rest}
      end)
      |> Enum.into(%{})
      |> then(&{tpid, &1})
    end)
    |> Enum.into(%{})
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
