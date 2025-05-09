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
  Returns LvProcess associated the given `pid` or `socket_id`.
  """
  @spec lv_process(pid :: pid()) :: LvProcess.t() | nil
  def lv_process(pid) when is_pid(pid) do
    debugged_lv_processes()
    |> Enum.find(&(&1.pid == pid))
  end

  @spec lv_process(socket_id :: String.t()) :: LvProcess.t() | nil
  def lv_process(socket_id) when is_binary(socket_id) do
    debugged_lv_processes()
    |> Enum.find(&(&1.socket_id == socket_id))
  end

  @doc """
  Finds a successor LiveView process based on the following priority:
  1. A non-nested, non-embedded process with matching transport_pid
  2. A non-nested process with matching transport_pid
  3. A single process with matching transport_pid
  4. A single non-nested, non-embedded process in the entire process list
  5. A single non-nested process in the entire process list
  6. A single process in the entire process list
  Returns nil if no suitable successor is found.
  """
  @spec successor_lv_process(lv_process :: LvProcess.t()) :: LvProcess.t() | nil
  def successor_lv_process(lv_process) do
    processes = debugged_lv_processes()
    transport_processes = Enum.filter(processes, &(&1.transport_pid == lv_process.transport_pid))

    cond do
      # Priority 1: Find a non-nested, non-embedded process with matching transport_pid
      successor = Enum.find(transport_processes, &(not &1.nested? and not &1.embedded?)) ->
        successor

      # Priority 2: Find a non-nested process with matching transport_pid
      successor = Enum.find(transport_processes, &(not &1.nested?)) ->
        successor

      # Priority 3: Use single process with matching transport_pid if it exists
      length(transport_processes) == 1 ->
        List.first(transport_processes)

      # Priority 4: Use single non-nested, non-embedded process if it exists
      length(lv_list = Enum.filter(processes, fn p -> not p.nested? and not p.embedded? end)) == 1 ->
        List.first(lv_list)

      # Priority 5: Use single non-nested process if it exists
      length(lv_list = Enum.filter(processes, fn p -> not p.nested? end)) == 1 ->
        List.first(lv_list)

      # Priority 6: Use single process if it exists
      length(processes) == 1 ->
        List.first(processes)

      true ->
        nil
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
