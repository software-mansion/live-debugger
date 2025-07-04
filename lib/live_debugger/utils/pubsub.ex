defmodule LiveDebugger.Utils.PubSub do
  @moduledoc """
  This module provides helpers for LiveDebugger's PubSub.
  """

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
  @spec component_deleted_topic() :: String.t()
  def component_deleted_topic() do
    "lvdbg/component_deleted"
  end

  @doc "Use `{:params_changed, params}` for broadcasting"
  @spec params_changed_topic(pid :: pid()) :: String.t()
  def params_changed_topic(pid) do
    "lvdbg/#{inspect(pid)}/params_changed"
  end

  @doc "Use `{:process_status, {status, pid}}` for broadcasting"
  @spec process_status_topic() :: String.t()
  def process_status_topic() do
    "lvdbg/process_status"
  end

  @doc "Use `{:render_trace, trace}` for broadcasting."
  @spec node_rendered_topic() :: String.t()
  def node_rendered_topic() do
    "lvdbg/node_rendered"
  end

  @doc "Use `{:state_changed, new_state, triggered_trace}` for broadcasting"
  @spec state_changed_topic(pid :: pid()) :: String.t()
  def state_changed_topic(pid) do
    "lvdbg/#{inspect(pid)}/*/state_changed"
  end

  @doc "Use `{:state_changed, new_state, triggered_trace}` for broadcasting"
  @spec state_changed_topic(
          pid :: pid(),
          node_id :: TreeNode.id()
        ) :: String.t()
  def state_changed_topic(pid, node_id) do
    "lvdbg/#{inspect(pid)}/#{inspect(node_id)}/state_changed"
  end

  @doc """
  It gives you traces of given callback in given node in given LiveView
  Used to update assigns based on render callback and for filtering traces

  Use `{:new_trace, trace}` or `{:updated_trace, trace}` for broadcasting.
  """
  @spec trace_topic(pid :: pid(), node_id :: TreeNode.id() | nil) :: String.t()
  def trace_topic(pid, node_id \\ nil) do
    "#{inspect(pid)}/#{inspect(node_id)}"
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
      Phoenix.PubSub.broadcast(pubsub_name(), topic, payload)
    end

    @impl true
    def subscribe!(topics) when is_list(topics) do
      topics
      |> Enum.each(&subscribe!(&1))

      :ok
    end

    @impl true
    def subscribe!(topic) do
      case Phoenix.PubSub.subscribe(pubsub_name(), topic) do
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
      Phoenix.PubSub.unsubscribe(pubsub_name(), topic)
    end

    defp pubsub_name() do
      Application.get_env(:live_debugger, :pubsub_name, LiveDebugger.PubSub)
    end
  end
end
