defmodule LiveDebugger.App.Debugger.AssociatedLiveViews.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.AssociatedLiveViews.Queries` context.
  """

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.API.LiveViewDiscovery

  @spec fetch_associated_live_views(pid()) :: {:ok, %{associated_lv_processes: map()}}
  def fetch_associated_live_views(transport_pid) do
    lv_processes =
      transport_pid
      |> LiveViewDiscovery.debugged_lv_processes()
      |> Enum.map(fn lv_process ->
        LvProcess.set_root_socket_id(
          lv_process,
          LiveViewDiscovery.get_root_socket_id(lv_process)
        )
      end)
      |> LiveViewDiscovery.group_lv_processes()
      |> Map.get(transport_pid, %{})

    {:ok, %{associated_lv_processes: lv_processes}}
  end
end
