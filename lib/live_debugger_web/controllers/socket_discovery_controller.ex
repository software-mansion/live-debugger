defmodule LiveDebuggerWeb.SocketDiscoveryController do
  use Phoenix.Controller

  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebuggerWeb.Helpers.RoutesHelper
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  def redirect(conn, %{"socket_id" => socket_id}) do
    window_id = conn |> fetch_query_params() |> Map.get(:query_params) |> Map.get("window_id")

    lv_process = LiveViewDiscoveryService.lv_process(socket_id)

    if lv_process do
      conn
      |> Phoenix.Controller.redirect(
        to: RoutesHelper.channel_dashboard(lv_process.pid, window_id)
      )
    else
      conn
    end
  end

  def update_window(conn, %{"window_id" => window_id}) do
    dbg("update_window: #{window_id}")
    socket_id = conn |> fetch_query_params() |> Map.get(:query_params) |> Map.get("socket_id")
    PubSubUtils.broadcast(window_id, {:window_updated, window_id, socket_id})

    json(conn, %{ok: true})
  end
end
