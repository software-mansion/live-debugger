defmodule LiveDebuggerWeb.ClientChannel do
  use Phoenix.Channel

  import LiveDebuggerWeb.Helpers
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  @impl true
  def join("client:" <> _session_id, _, socket) do
    dbg(socket)

    socket
    |> ok()
  end

  @impl true
  def handle_in("client-message", payload, socket) do
    IO.inspect(payload, label: "Client message received")
    dbg(socket)

    PubSubUtils.from_client_topic(socket.assigns.client_session_id)
    |> PubSubUtils.broadcast({:client_msg, payload})

    socket
    |> noreply()
  end

  @impl true
  def handle_info({:highlight, payload}, socket) do
    push(socket, "lvdbg:highlight", payload)

    socket
    |> noreply()
  end

  @impl true
  def handle_info({:pulse, payload}, socket) do
    push(socket, "lvdbg:pulse", payload)

    socket
    |> noreply()
  end
end
