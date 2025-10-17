defmodule LiveDebugger.App.Discovery.Queries do
  @moduledoc """
  Queries for the `LiveDebugger.App.Discovery` context.
  """

  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.API.LiveViewDiscovery
  alias LiveDebugger.Structs.LvProcess

  @doc """
  Fetches all active LiveView processes grouped by their transport PID.
  Performs delayed fetching to ensure processes are captured.
  """
  @spec fetch_grouped_lv_processes(transport_pid :: pid() | nil) ::
          {:ok,
           %{
             grouped_lv_processes: %{
               pid() => %{LvProcess.t() => [LvProcess.t()]}
             }
           }}
  def fetch_grouped_lv_processes(transport_pid \\ nil) do
    lv_processes =
      with [] <- fetch_lv_processes_after(200, transport_pid),
           [] <- fetch_lv_processes_after(800, transport_pid) do
        fetch_lv_processes_after(1000, transport_pid)
      end

    {:ok, %{grouped_lv_processes: LiveViewDiscovery.group_lv_processes(lv_processes)}}
  end

  @doc """
  Fetches all dead LiveView processes grouped by their transport PID.
  Retrieves states from storage and checks for process aliveness.
  """
  @spec fetch_dead_grouped_lv_processes() ::
          {:ok,
           %{
             dead_grouped_lv_processes: %{
               pid() => %{LvProcess.t() => [LvProcess.t()]}
             }
           }}
  def fetch_dead_grouped_lv_processes() do
    dead_lv_processes =
      StatesStorage.get_all_states()
      |> Enum.filter(fn {pid, %LvState{}} -> not Process.alive?(pid) end)
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&(LvProcess.new(&1.pid, &1.socket) |> LvProcess.set_alive(false)))

    {:ok, %{dead_grouped_lv_processes: LiveViewDiscovery.group_lv_processes(dead_lv_processes)}}
  end

  defp fetch_lv_processes_after(milliseconds, nil) do
    Process.sleep(milliseconds)
    LiveViewDiscovery.debugged_lv_processes()
  end

  defp fetch_lv_processes_after(milliseconds, transport_pid) do
    Process.sleep(milliseconds)
    LiveViewDiscovery.debugged_lv_processes(transport_pid)
  end
end
