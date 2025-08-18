defmodule LiveDebugger.Client.Socket do
  @moduledoc false

  use Phoenix.Socket

  channel("client:*", LiveDebugger.Client.Channel)

  @impl true
  def connect(%{"socketID" => socket_id}, socket) do
    socket = assign(socket, :debugged_socket_id, socket_id)
    {:ok, socket}
  end

  @impl true
  def id(socket), do: "client:#{socket.assigns.debugged_socket_id}"
end
