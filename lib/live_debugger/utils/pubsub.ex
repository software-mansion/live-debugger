defmodule LiveDebugger.Utils.PubSub do
  @moduledoc """
  This module provides helpers for LiveDebugger's PubSub.
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Structs.TreeNode

  @callback broadcast(topic :: String.t(), payload :: term()) :: :ok
  @callback subscribe!(topics :: [String.t()]) :: :ok
  @callback subscribe!(topic :: String.t()) :: :ok
  @callback unsubscribe(topics :: [String.t()]) :: :ok
  @callback unsubscribe(topic :: String.t()) :: :ok

  @spec broadcast(topic :: String.t(), payload :: term()) :: :ok
  def broadcast(topic, payload), do: impl().broadcast(topic, payload)

  @spec subscribe!(topics :: [String.t()]) :: :ok
  def subscribe!(topics) when is_list(topics), do: impl().subscribe!(topics)

  @spec subscribe!(topic :: String.t()) :: :ok
  def subscribe!(topic), do: impl().subscribe!(topic)

  @spec unsubscribe(topics :: [String.t()]) :: :ok
  def unsubscribe(topics) when is_list(topics), do: impl().unsubscribe(topics)

  @spec unsubscribe(topic :: String.t()) :: :ok
  def unsubscribe(topic), do: impl().unsubscribe(topic)

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

  @spec process_died_topic(pid :: pid()) :: String.t()
  def process_died_topic(pid) do
    "lvdbg/#{inspect(pid)}/process_died"
  end

  @spec process_died_topic() :: String.t()
  def process_died_topic() do
    "lvdbg/*/process_died"
  end

  @doc """
  It stands for `transport_pid/socket_id/node_id/function`.

  It gives you traces of given callback in given node in given LiveView
  Used to update assigns based on render callback and for filtering traces
  """
  @spec tsnf_topic(
          socket_id :: String.t(),
          transport_pid :: pid(),
          node_id :: TreeNode.id(),
          fun :: atom(),
          type :: :call | :return
        ) :: String.t()
  def tsnf_topic(socket_id, transport_pid, node_id, fun, type \\ :call) do
    "#{inspect(transport_pid)}/#{socket_id}/#{inspect(node_id)}/#{inspect(fun)}/#{inspect(type)}"
  end

  @doc """
  It stands for `transport_pid/socket_id/*/function`.

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

  @doc """
  Its stands for `*/*/*/function`.

  It gives you traces of all callbacks of given function
  """
  @spec ___f_topic(fun :: atom()) :: String.t()
  def ___f_topic(fun) do
    "/*/*/*/#{inspect(fun)}"
  end

  @spec impl() :: module()
  defp impl() do
    Application.get_env(
      :live_debugger,
      :pubsub_utils,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.Utils.PubSub

    @impl true
    def broadcast(topic, payload) do
      Phoenix.PubSub.broadcast(LiveDebugger.PubSub, topic, payload)
    end

    @impl true
    def subscribe!(topics) when is_list(topics) do
      topics
      |> Enum.each(&subscribe!(&1))

      :ok
    end

    @impl true
    def subscribe!(topic) do
      case Phoenix.PubSub.subscribe(LiveDebugger.PubSub, topic) do
        :ok -> :ok
        {:error, reason} -> raise reason
      end
    end

    @impl true
    def unsubscribe(topics) when is_list(topics) do
      topics
      |> Enum.each(&unsubscribe(&1))

      :ok
    end

    @impl true
    def unsubscribe(topic) do
      Phoenix.PubSub.unsubscribe(LiveDebugger.PubSub, topic)
    end
  end
end
