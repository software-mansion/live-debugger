defmodule LiveDebuggerRefactor.App.Web.Socket.ClientSocket do
  use Phoenix.Socket

  channel("client:*", LiveDebuggerRefactor.App.Web.Socket.ClientChannel)

  def connect(%{"sessionId" => client_session_id}, socket) do
    socket = assign(socket, :client_session_id, client_session_id)
    {:ok, socket}
  end

  def id(socket), do: "client:#{socket.assigns.client_session_id}"
end
