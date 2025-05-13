defmodule LiveDebuggerWeb.SocketDiscoveryController do
  use Phoenix.Controller

  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebuggerWeb.Helpers.RoutesHelper

  def redirect(conn, %{"socket_id" => socket_id}) do
    lv_process = LiveViewDiscoveryService.lv_process(socket_id)

    if lv_process do
      conn
      |> Phoenix.Controller.redirect(to: RoutesHelper.channel_dashboard(lv_process.pid))
    else
      conn
    end
  end
end
