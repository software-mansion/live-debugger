defmodule LiveDebugger.App.Discovery.Queries do
  @moduledoc """
  Queries for the `LiveDebugger.App.Discovery` context.
  """

  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.API.LiveViewDiscovery
  alias LiveDebugger.Structs.LvProcess

  @type grouped_lv_processes() :: %{pid() => %{LvProcess.t() => [LvProcess.t()]}}

  @doc """
  Fetches all active LiveView processes grouped by their transport PID.
  Performs delayed fetching to ensure processes are captured.
  """
  @spec fetch_grouped_lv_processes(transport_pid :: pid() | nil) ::
          {grouped_lv_processes :: grouped_lv_processes(),
           lv_processes_count :: non_neg_integer()}
  def fetch_grouped_lv_processes(transport_pid \\ nil) do
    lv_processes =
      with [] <- fetch_lv_processes_after(200, transport_pid),
           [] <- fetch_lv_processes_after(800, transport_pid) do
        fetch_lv_processes_after(1000, transport_pid)
      end

    {LiveViewDiscovery.group_lv_processes(lv_processes), length(lv_processes)}
  end

  @doc """
  Fetches all dead LiveView processes grouped by their transport PID.
  Retrieves states from storage and checks for process aliveness.
  """
  @spec fetch_dead_grouped_lv_processes() ::
          {dead_grouped_lv_processes :: grouped_lv_processes(),
           lv_processes_count :: non_neg_integer()}
  def fetch_dead_grouped_lv_processes() do
    dead_lv_processes =
      StatesStorage.get_all_states()
      |> Enum.filter(fn {pid, %LvState{}} -> not Process.alive?(pid) end)
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&(LvProcess.new(&1.pid, &1.socket) |> LvProcess.set_alive(false)))

    {LiveViewDiscovery.group_lv_processes(dead_lv_processes), length(dead_lv_processes)}
  end

  defp fetch_lv_processes_after(milliseconds, nil) do
    Process.sleep(milliseconds)

    LiveViewDiscovery.debugged_lv_processes()
    |> Enum.map(fn lv_process ->
      LvProcess.set_root_socket_id(lv_process, get_root_socket_id(lv_process))
    end)
  end

  defp get_root_socket_id(%LvProcess{embedded?: false, nested?: false} = lv_process) do
    lv_process.socket_id
  end

  defp get_root_socket_id(%LvProcess{embedded?: true, nested?: false} = lv_process) do
    case find_root_lv_process_over_transport_pid(lv_process.transport_pid) do
      %LvProcess{socket_id: socket_id} -> socket_id
      _ -> lv_process.socket_id
    end
  end

  defp get_root_socket_id(lv_process) do
    lv_process.root_pid
    |> LiveViewDiscovery.lv_process()
    |> case do
      %LvProcess{embedded?: false} = lv_process -> lv_process.socket_id
      %LvProcess{embedded?: true, nested?: false} = lv_process -> get_root_socket_id(lv_process)
      _ -> nil
    end
  end

  defp find_root_lv_process_over_transport_pid(transport_pid) do
    LiveViewDiscovery.debugged_lv_processes()
    |> Enum.find(fn
      %LvProcess{transport_pid: ^transport_pid, embedded?: false, nested?: false} -> true
      _ -> false
    end)
  end
end
