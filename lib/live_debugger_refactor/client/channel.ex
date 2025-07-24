defmodule LiveDebuggerRefactor.Client.Channel do
  @moduledoc """
  This is channel for communication between LiveDebugger processes and debugged LiveView browser.
  """
  use Phoenix.Channel

  @pubsub_name Application.compile_env(
                 :live_debugger,
                 :endpoint_pubsub_name,
                 LiveDebuggerRefactor.App.Web.Endpoint.PubSub
               )

  @impl true
  def join("client:" <> _debugged_socket_id, _params, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_in(message, payload, socket) do
    debugged_socket_id = socket.assigns.debugged_socket_id

    Phoenix.PubSub.broadcast!(
      @pubsub_name,
      "client:#{debugged_socket_id}:receive",
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
