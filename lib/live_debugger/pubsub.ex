defmodule LiveDebugger.Utils.PubSub do
  @moduledoc """
  This module provides helpers for LiveDebugger's PubSub.
  """

  alias Phoenix.PubSub
  alias LiveDebugger.Structs.LvProcess

  @type topic :: :new_trace | :node_changed

  @doc """
  Subscribes to the given topic.
  """
  @spec subscribe(LvProcess.t(), topic()) :: :ok | {:error, term()}
  def subscribe(lv_process, topic) do
    PubSub.subscribe(LiveDebugger.PubSub, topic(lv_process, topic))
  end

  @doc """
  Broadcasts a message to the given topic.
  """
  @spec broadcast(LvProcess.t(), topic(), term()) :: :ok | {:error, term()}
  def broadcast(lv_process, topic, payload) do
    PubSub.broadcast(LiveDebugger.PubSub, topic(lv_process, topic), payload)
  end

  defp topic(lv_process, :node_changed) do
    "lvdbg/#{inspect(lv_process.transport_pid)}/#{lv_process.socket_id}/node_changed"
  end

  # FYI this topic is temporary, it will be replaced after the new tracing system is implemented
  defp topic(lv_process, :new_trace) do
    "lvdbg/#{inspect(lv_process.transport_pid)}/#{lv_process.socket_id}/new_trace"
  end
end
