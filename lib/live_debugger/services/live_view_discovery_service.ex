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
  Returns LvProcess associated the given `pid`.
  """
  @spec lv_process(pid :: pid()) :: LvProcess.t() | nil
  def lv_process(pid) when is_pid(pid) do
    debugged_lv_processes()
    |> Enum.find(&(&1.pid == pid))
  end

  @doc """
  Finds potential successors LvProcesses.
  """
  @spec successor_lv_process(lv_process :: LvProcess.t()) :: LvProcess.t() | nil
  def successor_lv_process(lv_process) do
    with processes <- debugged_lv_processes(),
         processes <-
           Enum.filter(processes, &(&1.transport_pid == lv_process.transport_pid)),
         nil <- Enum.find(processes, &(not &1.nested? and not &1.embedded?)),
         nil <- Enum.find(processes, &(not &1.nested?)) do
      nil
    else
      lv_process -> lv_process
    end
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
    |> Enum.map(fn {tpid, grouped_by_tpid} ->
      grouped_by_tpid
      |> Enum.group_by(& &1.root_pid)
      |> Enum.map(fn {rpid, grouped_by_rpid} ->
        root_lv_process = Enum.find(grouped_by_rpid, &(&1.root_pid == rpid))
        rest = Enum.reject(grouped_by_rpid, &(&1.pid == rpid))

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

  @doc """
  Returns all children LvProcesses of the given `pid`.
  """
  @spec children_lv_processes(pid :: pid(), searched_lv_processes :: [LvProcess.t()] | nil) :: [
          LvProcess.t()
        ]
  def children_lv_processes(pid, searched_lv_processes \\ nil) do
    searched_lv_processes =
      if is_nil(searched_lv_processes) do
        debugged_lv_processes()
      else
        searched_lv_processes
      end

    searched_lv_processes
    |> Enum.filter(&(&1.parent_pid == pid))
    |> Enum.map(fn lv_process ->
      children = children_lv_processes(lv_process.pid, searched_lv_processes)

      [lv_process | children]
    end)
    |> List.flatten()
  end

  @spec liveview?(initial_call :: mfa() | nil | {}) :: boolean()
  defp liveview?(initial_call) when initial_call not in [nil, {}] do
    elem(initial_call, 1) == :mount
  end

  defp liveview?(_), do: false
end
