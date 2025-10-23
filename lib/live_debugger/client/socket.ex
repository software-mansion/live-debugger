defmodule LiveDebugger.Client.Socket do
  @moduledoc false

  use Phoenix.Socket

  channel("client:*", LiveDebugger.Client.Channel)

  @impl true
  def connect(%{"socketID" => socket_id} = params, socket) do
    socket =
      socket
      |> assign(:debugged_socket_id, socket_id)
      |> assign(:root_socket_ids, params["rootSocketIDs"] || %{})

    {:ok, socket}
  end

  @impl true
  def id(socket), do: "client:#{socket.assigns.debugged_socket_id}"
end
