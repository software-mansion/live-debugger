defmodule LiveDebuggerWeb.SocketDiscoveryController do
  use Phoenix.Controller

  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Utils.Parsers

  def redirect(conn, %{"socket_id" => socket_id}) do
    lv_process = LiveViewDiscoveryService.lv_process(socket_id)

    if lv_process do
      conn
      |> Phoenix.Controller.redirect(to: "/#{Parsers.pid_to_string(lv_process.pid)}")
    else
      conn
    end
  end
end
