defmodule LiveDebugger.Client.Channel do
  @moduledoc """
  This is channel for communication between LiveDebugger processes and debugged LiveView browser.
  """
  use Phoenix.Channel

  alias LiveDebugger.API.WindowsStorage

  # @pubsub_name LiveDebugger.Env.endpoint_pubsub_name()

  @impl true
  def join("client:" <> window_id, %{"fingerprint" => fingerprint}, socket) do
    WindowsStorage.save!(fingerprint, window_id)
    dbg("Joined window #{window_id} with fingerprint #{fingerprint}")
    {:ok, assign(socket, :window_id, window_id)}
  end

  @impl true
  def handle_in(
        "update_fingerprint",
        %{"fingerprint" => fingerprint, "previous_fingerprint" => previous_fingerprint},
        socket
      ) do
    window_id = socket.assigns.window_id
    WindowsStorage.delete!(previous_fingerprint)
    WindowsStorage.save!(fingerprint, window_id)

    dbg(
      "Updated fingerprint for window #{window_id} from #{previous_fingerprint} to #{fingerprint}"
    )

    {:reply, :ok, socket}
  end

  def handle_in("client_event", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({event, payload}, socket) do
    push(socket, event, payload)

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    WindowsStorage.delete_by_window_id!(socket.assigns.window_id)
    dbg("Terminated window #{socket.assigns.window_id}")
    {:ok, socket}
  end
end
