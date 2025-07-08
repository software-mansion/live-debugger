defmodule LiveDebuggerRefactor.Bus do
  @moduledoc """
  This module is responsible for broadcasting events inside LiveDebugger.
  """

  alias LiveDebuggerRefactor.Event

  @callback setup_bus_tree(children :: list()) :: list()

  @callback broadcast_event!(Event.t()) :: :ok
  @callback broadcast_event!(Event.t(), pid()) :: :ok
  @callback broadcast_trace!(Event.t()) :: :ok
  @callback broadcast_trace!(Event.t(), pid()) :: :ok
  @callback broadcast_state!(Event.t()) :: :ok
  @callback broadcast_state!(Event.t(), pid()) :: :ok

  @doc """
  Appends the bus children to the supervision tree.
  """
  @spec setup_bus_tree(children :: list()) :: list()
  def setup_bus_tree(children) do
    impl().setup_bus_tree(children)
  end

  @doc """
  Broadcast event to general topic: `lvdbg/*`.
  """
  @spec broadcast_event!(Event.t()) :: :ok
  def broadcast_event!(event) do
    impl().broadcast_event!(event)
  end

  @doc """
  Broadcast event to general topic with specific pid: `lvdbg/*` and `lvdbg/{pid}`.
  """
  @spec broadcast_event!(Event.t(), pid()) :: :ok
  def broadcast_event!(event, pid) do
    impl().broadcast_event!(event, pid)
  end

  @doc """
  Broadcast event to traces topic: `lvdbg/traces/*`.
  """
  @spec broadcast_trace!(Event.t()) :: :ok
  def broadcast_trace!(event) do
    impl().broadcast_trace!(event)
  end

  @doc """
  Broadcast event to traces topic with specific pid: `lvdbg/traces/*` and `lvdbg/traces/{pid}`.
  """
  @spec broadcast_trace!(Event.t(), pid()) :: :ok
  def broadcast_trace!(event, pid) do
    impl().broadcast_trace!(event, pid)
  end

  @doc """
  Broadcast event to states topic: `lvdbg/states/*`.
  """
  @spec broadcast_state!(Event.t()) :: :ok
  def broadcast_state!(event) do
    impl().broadcast_state!(event)
  end

  @doc """
  Broadcast event to states topic with specific pid: `lvdbg/states/*` and `lvdbg/states/{pid}`.
  """
  @spec broadcast_state!(Event.t(), pid()) :: :ok
  def broadcast_state!(event, pid) do
    impl().broadcast_state!(event, pid)
  end

  defp impl() do
    Application.get_env(:live_debugger, :bus, __MODULE__.Impl)
  end

  defmodule Impl do
    @moduledoc false

    @behaviour LiveDebuggerRefactor.Bus

    @pubsub_name Application.compile_env(:live_debugger, :pubsub_name, LiveDebugger.PubSub)

    def setup_bus_tree(children) do
      [{Phoenix.PubSub, name: @pubsub_name} | children]
    end

    def broadcast_event!(event) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/*", event)
    end

    def broadcast_event!(event, pid) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/*", event)
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/#{pid}", event)
    end

    def broadcast_trace!(event) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/*", event)
    end

    def broadcast_trace!(event, pid) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/*", event)
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/#{pid}", event)
    end

    def broadcast_state!(event) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/*", event)
    end

    def broadcast_state!(event, pid) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/*", event)
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/#{pid}", event)
    end
  end
end
