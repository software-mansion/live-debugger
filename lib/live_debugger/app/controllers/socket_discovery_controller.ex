defmodule LiveDebugger.App.Controllers.SocketDiscoveryController do
  use Phoenix.Controller, formats: []

  alias LiveDebugger.API.LiveViewDiscovery
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper

  require Logger

  def redirect(conn, %{"socket_id" => socket_id}) do
    params = conn |> fetch_query_params() |> Map.get(:params)
    node_id = Map.get(params, "node_id")
    root_id = Map.get(params, "root_id")

    LiveViewDiscovery.debugged_lv_processes()
    |> maybe_filter_by_root_id(root_id)
    |> filter_by_socket_id(socket_id)
    |> case do
      [lv_process] ->
        conn
        |> Phoenix.Controller.redirect(
          to: RoutesHelper.debugger_node_inspector(lv_process.pid, node_id)
        )

      result ->
        Logger.error(
          "Could not find single LiveView process for socket_id: #{socket_id}, node_id: #{node_id}, root_id: #{root_id}, result: #{inspect(result)}"
        )

        conn
        |> Phoenix.Controller.redirect(to: RoutesHelper.error("multiple_live_views"))
    end
  end

  defp filter_by_socket_id(processes, socket_id) do
    Enum.filter(processes, &(&1.socket_id == socket_id))
  end

  defp maybe_filter_by_root_id(processes, nil), do: processes

  defp maybe_filter_by_root_id(processes, root_id) do
    processes
    |> Enum.find(&(&1.socket_id == root_id))
    |> case do
      nil -> processes
      root_process -> Enum.filter(processes, &(&1.transport_pid == root_process.transport_pid))
    end
  end
end
