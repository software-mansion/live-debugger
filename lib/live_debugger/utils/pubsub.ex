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

  @doc "Use `{:component_deleted, delete_trace}` for broadcasting"
  @spec component_deleted_topic(trace :: Trace.t()) :: String.t()
  def component_deleted_topic(trace) do
    socket_id = trace.socket_id
    transport_pid = trace.transport_pid

    component_deleted_topic(socket_id, transport_pid)
  end

  @doc "Use `{:component_deleted, delete_trace}` for broadcasting"
  @spec component_deleted_topic(socket_id :: String.t(), transport_pid :: pid()) :: String.t()
  def component_deleted_topic(socket_id, transport_pid)
      when is_binary(socket_id) and is_pid(transport_pid) do
    "lvdbg/#{inspect(transport_pid)}/#{socket_id}/component_deleted"
  end

  @doc "Use `{:component_deleted, delete_trace}` for broadcasting"
  @spec component_deleted_topic() :: String.t()
  def component_deleted_topic() do
    "lvdbg/*/*/component_deleted"
  end

  @doc "Use `{:node_changed, node_id}` for broadcasting"
  @spec node_changed_topic(socket_id :: String.t()) :: String.t()
  def node_changed_topic(socket_id) when is_binary(socket_id) do
    "lvdbg/#{socket_id}/node_changed"
  end

  @doc "Use `{:process_status, {status, pid}}` for broadcasting"
  @spec process_status_topic() :: String.t()
  def process_status_topic() do
    "lvdbg/process_status"
  end

  @doc "Use `{:state_changed, new_state, triggered_trace}` for broadcasting"
  @spec state_changed_topic(
          socket_id :: String.t(),
          transport_pid :: pid()
        ) :: String.t()
  def state_changed_topic(socket_id, transport_pid)
      when is_pid(transport_pid) and is_binary(socket_id) do
    "lvdbg/#{inspect(transport_pid)}/#{socket_id}/*/state_changed"
  end

  @doc "Use `{:state_changed, new_state, triggered_trace}` for broadcasting"
  @spec state_changed_topic(
          socket_id :: String.t(),
          transport_pid :: pid(),
          node_id :: TreeNode.id()
        ) :: String.t()
  def state_changed_topic(socket_id, transport_pid, node_id)
      when is_pid(transport_pid) and is_binary(socket_id) do
    "lvdbg/#{inspect(transport_pid)}/#{socket_id}/#{inspect(node_id)}/state_changed"
  end

  @doc "Use `{:render_trace, trace}` for broadcasting."
  @spec node_rendered() :: String.t()
  def node_rendered() do
    "lvdbg/node_rendered"
  end

  @doc """
  It stands for `transport_pid/socket_id/node_id/function`.

  It gives you traces of given callback in given node in given LiveView
  Used to update assigns based on render callback and for filtering traces

  Use `{:new_trace, trace}` or `{:updated_trace, trace}` for broadcasting.
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

  Use `{:new_trace, trace}` or `{:updated_trace, trace}` for broadcasting.
  """
  @spec ts_f_topic(
          socket_id :: String.t(),
          transport_pid :: pid(),
          fun :: atom(),
          type :: :call | :return
        ) :: String.t()
  def ts_f_topic(socket_id, transport_pid, fun, type \\ :call) do
    "#{inspect(transport_pid)}/#{socket_id}/*/#{inspect(fun)}/#{inspect(type)}"
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
