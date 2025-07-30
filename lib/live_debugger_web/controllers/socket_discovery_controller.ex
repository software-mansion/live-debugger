defmodule LiveDebuggerWeb.SocketDiscoveryController do
  use Phoenix.Controller

  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebuggerWeb.Helpers.RoutesHelper

  def redirect(conn, %{"socket_id" => socket_id}) do
    lv_process = LiveViewDiscoveryService.lv_process(socket_id)
    node_id = conn |> fetch_query_params() |> Map.get(:params) |> Map.get("node_id")

    if lv_process do
      conn
      |> Phoenix.Controller.redirect(to: RoutesHelper.channel_dashboard(lv_process.pid, node_id))
    else
      conn
    end
  end
end
