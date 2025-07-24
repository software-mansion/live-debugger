defmodule LiveDebuggerRefactor.Client.Socket do
  use Phoenix.Socket

  channel("client:*", LiveDebuggerRefactor.Client.Channel)

  def connect(%{"sessionId" => session_id}, socket) do
    socket = assign(socket, :debugged_socket_id, session_id)
    {:ok, socket}
  end

  def id(socket), do: "client:#{socket.assigns.debugged_socket_id}"
end
