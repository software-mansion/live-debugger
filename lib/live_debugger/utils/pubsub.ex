defmodule LiveDebugger.Utils.PubSub do
  @moduledoc """
  This module provides helpers for LiveDebugger's PubSub.
  """

  alias LiveDebugger.Structs.Trace

  @spec broadcast(topics :: [String.t()], payload :: term()) :: :ok
  def broadcast(topics, payload) when is_list(topics) do
    topics
    |> Enum.each(&broadcast(&1, payload))

    :ok
  end

  @spec broadcast(topic :: String.t(), payload :: term()) :: :ok
  def broadcast(topic, payload) do
    Phoenix.PubSub.broadcast(LiveDebugger.PubSub, topic, payload)
  end

  @spec subscribe(topics :: [String.t()]) :: :ok
  def subscribe(topics) when is_list(topics) do
    topics
    |> Enum.each(&subscribe(&1))

    :ok
  end

  @spec subscribe(topic :: String.t()) :: :ok
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(LiveDebugger.PubSub, topic)
  end

  @spec node_changed_topic(socket_id :: String.t()) :: String.t()
  def node_changed_topic(socket_id) do
    "lvdbg/#{socket_id}/node_changed"
  end

  @spec tree_updated_topic(trace :: Trace.t()) :: String.t()
  def tree_updated_topic(trace) do
    socket_id = trace.socket_id
    transport_pid = inspect(trace.transport_pid)

    "lvdbg/#{socket_id}/#{transport_pid}/tree_updated"
  end

  @spec trace_topics(trace :: Trace.t()) :: [String.t()]
  def trace_topics(trace) do
    socket_id = trace.socket_id
    node_id = inspect(Trace.node_id(trace))
    transport_pid = inspect(trace.transport_pid)
    fun = inspect(trace.function)

    [
      "#{socket_id}/#{transport_pid}/#{node_id}/#{fun}",
      "#{socket_id}/#{transport_pid}/#{node_id}/*",
      "#{socket_id}/#{transport_pid}/*/*"
    ]
  end
end
