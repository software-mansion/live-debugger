defmodule LiveDebugger.Client.Channel do
  @moduledoc """
  This is channel for communication between LiveDebugger processes and debugged LiveView browser.
  """
  use Phoenix.Channel

  alias LiveDebugger.API.WindowsStorage

  # @pubsub_name LiveDebugger.Env.endpoint_pubsub_name()

  @impl true
  def join("client:init", _payload, socket) do
    {:ok, socket}
  end

  def join("client:" <> window_id, _payload, socket) do
    {:ok, assign(socket, :window_id, window_id)}
  end

  @impl true
  def handle_in("register", %{"window_id" => window_id, "fingerprint" => fingerprint}, socket) do
    WindowsStorage.save!(fingerprint, window_id)
    dbg("Registered window #{window_id} with fingerprint #{fingerprint}")
    {:reply, :ok, socket}
  end

  def handle_in(
        "update_fingerprint",
        %{
          "window_id" => window_id,
          "fingerprint" => fingerprint,
          "previous_fingerprint" => previous_fingerprint
        },
        socket
      ) do
    WindowsStorage.delete!(previous_fingerprint)
    WindowsStorage.save!(fingerprint, window_id)

    dbg(
      "Updated fingerprint for window #{window_id} from #{previous_fingerprint} to #{fingerprint}"
    )

    {:reply, :ok, socket}
  end

  def handle_in("client_event", payload, socket) do
    window_id = socket.assigns.window_id
    dbg(%{event: "client_event", window_id: window_id, payload: payload})
    {:noreply, socket}
  end

  @impl true
  def handle_info({event, payload}, socket) do
    push(socket, event, payload)

    {:noreply, socket}
  end
end
