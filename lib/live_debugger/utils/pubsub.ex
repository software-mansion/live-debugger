defmodule LiveDebugger.Utils.PubSub do
  @moduledoc """
  This module provides helpers for LiveDebugger's PubSub.
  """
  alias LiveDebugger.Structs.LvProcess

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

  @spec subscribe(topic :: String.t()) :: :ok
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(LiveDebugger.PubSub, topic)
  end

  @spec node_changed_topic(socket_id :: String.t()) :: String.t()
  def node_changed_topic(socket_id) do
    "lvdbg/#{socket_id}/node_changed"
  end

  # FYI this topic is temporary, it will be replaced after the new tracing system is implemented
  @spec node_trace_topic(lv_process :: LvProcess.t()) :: String.t()
  def node_trace_topic(lv_process) do
    "lvdbg/#{inspect(lv_process.transport_pid)}/#{lv_process.socket_id}/new_trace"
  end

  # FYI this topic is temporary, it will be replaced after the new tracing system is implemented
  @spec session_trace_topic(lv_process :: LvProcess.t()) :: String.t()
  def session_trace_topic(lv_process) do
    "lvdbg/#{inspect(lv_process.transport_pid)}/new_trace"
  end
end
