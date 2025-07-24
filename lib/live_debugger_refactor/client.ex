defmodule LiveDebuggerRefactor.Client do
  @moduledoc """
  This module provides a set of functions to communicate with the client's browser where debugged LiveView is running.
  """

  @pubsub_name Application.compile_env(
                 :live_debugger,
                 :endpoint_pubsub_name,
                 LiveDebuggerRefactor.App.Web.Endpoint.PubSub
               )

  @doc """
  Pushes event to the client.

  ## Examples

  ```elixir
  LiveDebuggerRefactor.Client.push_event!("debugged_socket_id", "event", %{"key" => "value"})
  ```
  """
  @spec push_event!(String.t(), String.t(), map()) :: :ok
  def push_event!(debugged_socket_id, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast!(@pubsub_name, "client:#{debugged_socket_id}", {event, payload})
  end

  @doc """
  Subscribes to events from the client. You have to prepare `handle_info/2` handler for incoming events.
  Events are in form of tuple `{event :: String.t(), payload :: map()}`.

  ## Examples

  ```elixir
  LiveDebuggerRefactor.Client.receive_events("debugged_socket_id")

  # ...

  def handle_info({event, payload}, state) do
    # handle event
    {:noreply, state}
  end
  ```
  """
  @spec receive_events(String.t()) :: :ok | {:error, term()}
  def receive_events(debugged_socket_id) do
    Phoenix.PubSub.subscribe(@pubsub_name, "client:#{debugged_socket_id}:receive")
  end
end
