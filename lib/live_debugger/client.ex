defmodule LiveDebugger.Client do
  @moduledoc """
  This module provides a set of functions to communicate with the client's browser where debugged LiveView is running.
  """

  @callback push_event!(String.t(), String.t(), map()) :: :ok
  @callback receive_events(String.t()) :: :ok | {:error, term()}
  @callback receive_events() :: :ok | {:error, term()}

  @doc """
  Pushes event to the client.

  ## Examples

      LiveDebugger.Client.push_event!("debugged_socket_id", "event", %{"key" => "value"})
  """
  @spec push_event!(String.t(), String.t(), map()) :: :ok
  def push_event!(debugged_socket_id, event, payload \\ %{}) do
    impl().push_event!(debugged_socket_id, event, payload)
  end

  @doc """
  Subscribes to events from the client with specific debugged socket id.
  You have to prepare `handle_info/2` handler for incoming events.
  Events are in form of tuple `{event :: String.t(), payload :: map()}`.

  ## Examples

      LiveDebugger.Client.receive_events("debugged_socket_id")

      # ...

      def handle_info({event, payload}, state) do
        # handle event
        {:noreply, state}
      end
  """
  @spec receive_events(String.t()) :: :ok | {:error, term()}
  def receive_events(debugged_socket_id) do
    impl().receive_events(debugged_socket_id)
  end

  @doc """
  Subscribes to events from the client with any debugged socket id.
  You have to prepare `handle_info/2` handler for incoming events.
  Events are in form of tuple `{event :: String.t(), payload :: map()}`.
  """
  @spec receive_events() :: :ok | {:error, term()}
  def receive_events() do
    impl().receive_events()
  end

  defp impl do
    Application.get_env(:live_debugger, :client, __MODULE__.Impl)
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.Client

    @pubsub_name LiveDebugger.Env.endpoint_pubsub_name()

    @impl true
    def push_event!(debugged_socket_id, event, payload \\ %{}) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "client:#{debugged_socket_id}", {event, payload})
    end

    @impl true
    def receive_events(debugged_socket_id) do
      Phoenix.PubSub.subscribe(@pubsub_name, "client:#{debugged_socket_id}:receive")
    end

    @impl true
    def receive_events() do
      Phoenix.PubSub.subscribe(@pubsub_name, "client:receive")
    end
  end
end
