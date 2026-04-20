defmodule LiveDebugger.Client.Channel do
  @moduledoc """
  This is channel for communication between LiveDebugger processes and debugged LiveView browser.
  """
  use Phoenix.Channel, log_join: false, log_handle_in: false

  @pubsub_name LiveDebugger.Env.endpoint_pubsub_name()

  @impl true
  def join("client:" <> _debugged_socket_id, _params, socket) do
    Phoenix.PubSub.subscribe(@pubsub_name, "client:*")

    socket.assigns.root_socket_ids
    |> Enum.each(fn {_, socket_id} ->
      Phoenix.PubSub.subscribe(@pubsub_name, "client:#{socket_id}")
    end)

    {:ok, socket}
  end

  @impl true
  def handle_in("tour:" <> _ = message, payload, socket) do
    Phoenix.PubSub.broadcast!(
      @pubsub_name,
      "client:tour:receive",
      {message, payload}
    )

    {:noreply, socket}
  end

  def handle_in(message, payload, socket) do
    debugged_socket_id = socket.assigns.debugged_socket_id

    Phoenix.PubSub.broadcast!(
      @pubsub_name,
      "client:#{debugged_socket_id}:receive",
      {message, payload}
    )

    Phoenix.PubSub.broadcast!(
      @pubsub_name,
      "client:receive",
      {message, payload}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({event, payload}, socket) do
    push(socket, event, payload)

    {:noreply, socket}
  end
end
