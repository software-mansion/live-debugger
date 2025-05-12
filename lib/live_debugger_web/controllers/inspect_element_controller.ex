defmodule LiveDebuggerWeb.InspectElementController do
  use Phoenix.Controller

  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  def broadcast(conn, _) do
    with {:ok, data, _} <- Plug.Conn.read_body(conn),
         {:ok, data} <- Jason.decode(data),
         %{"componentId" => component_id, "sessionId" => session_id} <- data do
      PubSubUtils.broadcast(
        "lvdbg/inspect-element/#{session_id}",
        {:inspect_component, component_id}
      )
    end

    json(conn, %{ok: true})
  end
end
