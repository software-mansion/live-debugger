defmodule LiveDebugger.Client.Channel do
  @moduledoc """
  This is channel for communication between LiveDebugger processes and debugged LiveView browser.
  """
  use Phoenix.Channel

  @pubsub_name LiveDebugger.Env.endpoint_pubsub_name()

  @impl true
  def join("client:init", _payload, socket) do
    {:ok, socket}
  end

  def join("client:" <> window_id, _payload, socket) do
    {:ok, assign(socket, :window_id, window_id)}
  end

  @impl true
  def handle_in("register", %{"window_id" => window_id, "fingerprint" => fingerprint}, socket) do
    dbg(%{window_id: window_id, fingerprint: fingerprint})
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
    dbg(%{
      window_id: window_id,
      fingerprint: fingerprint,
      previous_fingerprint: previous_fingerprint
    })

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
