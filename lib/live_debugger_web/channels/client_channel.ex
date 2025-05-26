defmodule LiveDebuggerWeb.ClientChannel do
  use Phoenix.Channel

  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  def join("client", _, socket) do
    PubSubUtils.subscribe!("client")
    {:ok, socket}
  end

  def handle_in("client-message", payload, socket) do
    IO.inspect(payload, label: "Client message received")
    {:noreply, socket}
  end

  def handle_info({:client, payload}, socket) do
    push(socket, "lvdbg-message", payload)
    {:noreply, socket}
  end
end
