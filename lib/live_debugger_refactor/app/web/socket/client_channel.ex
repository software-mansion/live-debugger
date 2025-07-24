defmodule LiveDebuggerRefactor.App.Web.Socket.ClientChannel do
  @moduledoc """
  This is channel for communication between LiveDebugger processes and debugged LiveView browser client.
  """
  use Phoenix.Channel

  @impl true
  def join("client:" <> _session_id = topic, _params, socket) do
    dbg("Joined client channel:")
    dbg(topic)
    # dbg(self())
    {:ok, socket}
  end

  @impl true
  def handle_in("client-message", payload, socket) do
    dbg("Received client message:")
    dbg(payload)

    {:noreply, socket}
  end

  @impl true
  def handle_info(payload, socket) do
    dbg("Received info:")
    dbg(payload)
    push(socket, "test", payload) |> dbg()

    {:noreply, socket}
  end
end
