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
  @spec fetch_grouped_lv_processes() ::
          {grouped_lv_processes :: grouped_lv_processes(),
           lv_processes_count :: non_neg_integer()}
  def fetch_grouped_lv_processes() do
    lv_processes =
      with [] <- fetch_lv_processes_after(0),
           [] <- fetch_lv_processes_after(500) do
        fetch_lv_processes_after(1000)
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

  defp fetch_lv_processes_after(milliseconds) do
    Process.sleep(milliseconds)

    LiveViewDiscovery.debugged_lv_processes()
    |> Enum.map(fn lv_process ->
      LvProcess.set_root_socket_id(lv_process, LiveViewDiscovery.get_root_socket_id(lv_process))
    end)
  end
end
