defmodule LiveDebugger.App.Discovery.Queries do
  @moduledoc """
  Queries for the `LiveDebugger.App.Discovery` context.
  """

  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.API.LiveViewDiscovery
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.API.WindowsStorage

  @type grouped_lv_processes() :: %{pid() => %{LvProcess.t() => [LvProcess.t()]}}

  @doc """
  Fetches all active LiveView processes grouped by their transport PID.
  Performs delayed fetching to ensure processes are captured.
  When a window_id is not found for a transport, retries from the beginning
  (re-fetching debugged_lv_processes) because the set of processes may have changed.
  """
  @spec fetch_grouped_lv_processes() ::
          {grouped_lv_processes :: grouped_lv_processes(),
           lv_processes_count :: non_neg_integer()}
  def fetch_grouped_lv_processes() do
    retries_timeouts = [0, 200, 400, 800]

    lv_processes =
      Enum.reduce_while(retries_timeouts, [], fn timeout, _acc ->
        Process.sleep(timeout)

        case LiveViewDiscovery.debugged_lv_processes() do
          [] ->
            {:cont, []}

          lv_processes ->
            fingerprint_by_transport_pid =
              lv_processes
              |> Enum.group_by(& &1.transport_pid)
              |> Enum.map(fn {transport_pid, processes} ->
                {transport_pid, WindowsStorage.create_fingerprint(processes)}
              end)

            transport_pid_to_window_id =
              Enum.map(fingerprint_by_transport_pid, fn {transport_pid, fingerprint} ->
                {transport_pid, WindowsStorage.get_window_id!(fingerprint)}
              end)
              |> Enum.into(%{})

            all_window_ids_found? =
              Enum.all?(transport_pid_to_window_id, fn {_, window_id} -> window_id != nil end)

            if all_window_ids_found? do
              lv_processes =
                Enum.map(
                  lv_processes,
                  &LvProcess.set_window_id(&1, transport_pid_to_window_id[&1.transport_pid])
                )

              {:halt, lv_processes}
            else
              {:cont, []}
            end
        end
      end)

    {
      LiveViewDiscovery.group_lv_processes(lv_processes),
      length(lv_processes)
    }
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
end
