defmodule LiveDebugger.Services.LiveViewDiscoveryService do
  @moduledoc """
  This module provides functions that discovers LiveView processes in the debugged application.
  """
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
  Returns all LiveDebugger's LvProcesses associated with the given `transport_pid`.
  """
  @spec debugged_lv_processes(transport_pid :: pid()) :: [LvProcess.t()]
  def debugged_lv_processes(transport_pid) do
    debugged_lv_processes()
    |> Enum.filter(&(&1.transport_pid == transport_pid))
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
  2. A single process with matching transport_pid
  3. A single non-nested, non-embedded process in the entire process list with matching module
  4. A single non-nested process in the entire process list with matching module
  5. A single process in the entire process list with matching module
  Returns nil if no suitable successor is found.
  """
  @spec successor_lv_process(lv_process :: LvProcess.t()) :: LvProcess.t() | nil
  def successor_lv_process(lv_process) do
    processes = debugged_lv_processes()
    module = lv_process.module
    transport_processes = Enum.filter(processes, &(&1.transport_pid == lv_process.transport_pid))

    find_successor_by_priority(transport_processes, processes, module)
  end

  defp find_successor_by_priority(transport_processes, all_processes, module) do
    find_first_match([
      # Priority 1: Find a non-nested, non-embedded process with matching transport_pid
      fn -> find_non_nested_non_embedded(transport_processes) end,
      # Priority 2: Use single process with matching transport_pid if it exists
      fn -> find_single_process(transport_processes) end,
      # Priority 3: Use single non-nested, non-embedded process if it exists
      fn -> find_single_non_nested_non_embedded(all_processes, module) end,
      # Priority 4: Use single non-nested process if it exists
      fn -> find_single_non_nested(all_processes, module) end,
      # Priority 5: Use single process if it exists
      fn -> find_single_process(all_processes, module) end
    ])
  end

  defp find_first_match(functions) do
    Enum.reduce_while(functions, nil, fn fun, _acc ->
      case fun.() do
        nil -> {:cont, nil}
        result -> {:halt, result}
      end
    end)
  end

  defp find_non_nested_non_embedded(processes) do
    Enum.find(processes, &(not &1.nested? and not &1.embedded?))
  end

  defp find_single_process(processes, module) do
    processes
    |> Enum.filter(&(&1.module == module))
    |> find_single_process()
  end

  defp find_single_non_nested_non_embedded(processes, module) do
    processes
    |> Enum.filter(&(not &1.nested? and not &1.embedded? and &1.module == module))
    |> find_single_process()
  end

  defp find_single_non_nested(processes, module) do
    processes
    |> Enum.filter(&(not &1.nested? and &1.module == module))
    |> find_single_process()
  end

  defp find_single_process(processes) do
    if length(processes) == 1, do: List.first(processes), else: nil
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
    LiveDebugger.Services.LiveViewService.list_liveviews()
    |> Enum.reject(&(&1.pid == self()))
    |> Enum.map(&LvProcess.new(&1.pid))
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
end
