defmodule LiveDebugger.Utils.PubSub do
  @moduledoc """
  This module provides helpers for LiveDebugger's PubSub.
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Structs.TreeNode

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

  @spec unsubscribe(topics :: [String.t()]) :: :ok
  def unsubscribe(topics) when is_list(topics) do
    topics
    |> Enum.each(&unsubscribe(&1))

    :ok
  end

  @spec unsubscribe(topic :: String.t()) :: :ok
  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(LiveDebugger.PubSub, topic)
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

  @doc """
  It stands for transport_pid/socket_id/node_id/function.

  It gives you traces of given callback in given node in given LiveView
  Used to update assigns based on render callback and for filtering traces
  """
  @spec tsnf_topic(
          socket_id :: String.t(),
          transport_pid :: pid(),
          node_id :: TreeNode.id(),
          fun :: atom()
        ) :: String.t()
  def tsnf_topic(socket_id, transport_pid, node_id, fun) do
    "#{inspect(transport_pid)}/#{socket_id}/#{inspect(node_id)}/#{inspect(fun)}"
  end

  @doc """
  It stands for transport_pid/socket_id/*/function.

  It gives you traces of given callback in all nodes of given LiveView
  Used for detecting new nodes in sidebar
  """
  @spec ts_f_topic(
          socket_id :: String.t(),
          transport_pid :: pid(),
          fun :: atom()
        ) :: String.t()
  def ts_f_topic(socket_id, transport_pid, fun) do
    "#{inspect(transport_pid)}/#{socket_id}/*/#{inspect(fun)}"
  end
end
