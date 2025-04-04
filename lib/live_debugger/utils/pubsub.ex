defmodule LiveDebugger.Utils.PubSub do
  @moduledoc """
  This module provides helpers for LiveDebugger's PubSub.
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Structs.TreeNode

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

  @spec unsubscribe(topic :: String.t()) :: :ok
  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(LiveDebugger.PubSub, topic)
  end

  @spec trace_topics(trace :: Trace.t()) :: [String.t()]
  def trace_topics(trace) do
    socket_id = trace.socket_id
    node_id = Trace.node_id(trace)
    transport_pid = trace.transport_pid
    fun = trace.function

    [
      trace_topic(socket_id, transport_pid, node_id, fun),
      trace_topic(socket_id, transport_pid, fun),
      trace_topic(socket_id, transport_pid, node_id),
      trace_topic(socket_id, transport_pid)
    ]
  end

  @spec component_deleted_topic(trace :: Trace.t()) :: String.t()
  def component_deleted_topic(trace) do
    socket_id = trace.socket_id
    transport_pid = trace.transport_pid

    component_deleted_topic(socket_id, transport_pid)
  end

  @spec node_changed_topic(socket_id :: String.t()) :: String.t()
  def node_changed_topic(socket_id) do
    "lvdbg/#{socket_id}/node_changed"
  end

  @spec component_deleted_topic(socket_id :: String.t(), transport_pid :: pid()) :: String.t()
  def component_deleted_topic(socket_id, transport_pid) do
    "lvdbg/#{inspect(transport_pid)}/#{socket_id}/component_deleted"
  end

  @spec trace_topic(String.t(), pid(), TreeNode.id(), atom()) :: String.t()
  def trace_topic(socket_id, transport_pid, node_id, fun) do
    "#{inspect(transport_pid)}/#{socket_id}/#{inspect(node_id)}/#{inspect(fun)}"
  end

  @spec trace_topic(String.t(), pid(), atom()) :: String.t()
  def trace_topic(socket_id, transport_pid, fun) when is_atom(fun) do
    "#{inspect(transport_pid)}/#{socket_id}/*/#{inspect(fun)}"
  end

  @spec trace_topic(String.t(), pid(), TreeNode.id()) :: String.t()
  def trace_topic(socket_id, transport_pid, node_id) do
    "#{inspect(transport_pid)}/#{socket_id}/#{inspect(node_id)}/*"
  end

  @spec trace_topic(String.t(), pid()) :: String.t()
  def trace_topic(socket_id, transport_pid) do
    "#{inspect(transport_pid)}/#{socket_id}/*/*"
  end
end
