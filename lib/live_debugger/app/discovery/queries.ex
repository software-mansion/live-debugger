defmodule LiveDebugger.App.Discovery.Queries do
  @moduledoc """
  Queries for the `LiveDebugger.App.Discovery` context.
  """
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

  defp fetch_lv_processes_after(milliseconds, nil) do
    Process.sleep(milliseconds)
    LiveViewDiscovery.debugged_lv_processes()
  end

  defp fetch_lv_processes_after(milliseconds, transport_pid) do
    Process.sleep(milliseconds)
    LiveViewDiscovery.debugged_lv_processes(transport_pid)
  end
end
