defmodule LiveDebugger.Client.Channel do
  @moduledoc """
  This is channel for communication between LiveDebugger processes and debugged LiveView browser.
  """
  use Phoenix.Channel

  alias LiveDebugger.API.WindowsStorage

  @pubsub_name LiveDebugger.Env.endpoint_pubsub_name()

  @impl true
  def join("client:" <> window_id, %{"fingerprint" => fingerprint}, socket) do
    Phoenix.PubSub.subscribe(@pubsub_name, "client:*")
    WindowsStorage.save!(fingerprint, window_id)

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

    {:reply, :ok, socket}
  end

  def handle_in(event, payload, socket) when is_map(payload) do
    window_id = socket.assigns.window_id
    message = {event, Map.put(payload, "window_id", window_id)}
    Phoenix.PubSub.broadcast!(@pubsub_name, "client:#{window_id}:receive", message)
    Phoenix.PubSub.broadcast!(@pubsub_name, "client:*:receive", message)

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
    {:ok, socket}
  end
end
