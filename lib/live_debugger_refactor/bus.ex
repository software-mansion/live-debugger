defmodule LiveDebuggerRefactor.Bus do
  @moduledoc """
  This module is responsible for broadcasting events inside LiveDebugger.
  """

  alias LiveDebuggerRefactor.Event

  @callback setup_bus_tree(children :: list()) :: list()

  @callback general_broadcast!(Event.t()) :: :ok
  @callback general_broadcast!(Event.t(), pid()) :: :ok
  @callback traces_broadcast!(Event.t()) :: :ok
  @callback traces_broadcast!(Event.t(), pid()) :: :ok
  @callback states_broadcast!(Event.t()) :: :ok
  @callback states_broadcast!(Event.t(), pid()) :: :ok

  @doc """
  Appends the bus children to the supervision tree.
  """
  @spec setup_bus_tree(children :: list()) :: list()
  def setup_bus_tree(children) do
    impl().setup_bus_tree(children)
  end

  @doc """
  Broadcast event to general topic `lvdbg/*`.
  """
  @spec general_broadcast!(Event.t()) :: :ok
  def general_broadcast!(event) do
    impl().general_broadcast!(event)
  end

  @doc """
  Broadcast event to general topic with specific pid `lvdbg/{pid}`.
  """
  @spec general_broadcast!(Event.t(), pid()) :: :ok
  def general_broadcast!(event, pid) do
    impl().general_broadcast!(event, pid)
  end

  @doc """
  Broadcast event to traces topic `lvdbg/traces/*`.
  """
  @spec traces_broadcast!(Event.t()) :: :ok
  def traces_broadcast!(event) do
    impl().traces_broadcast!(event)
  end

  @doc """
  Broadcast event to traces topic with specific pid `lvdbg/traces/{pid}`.
  """
  @spec traces_broadcast!(Event.t(), pid()) :: :ok
  def traces_broadcast!(event, pid) do
    impl().traces_broadcast!(event, pid)
  end

  @doc """
  Broadcast event to states topic `lvdbg/states/*`.
  """
  @spec states_broadcast!(Event.t()) :: :ok
  def states_broadcast!(event) do
    impl().states_broadcast!(event)
  end

  @doc """
  Broadcast event to states topic with specific pid `lvdbg/states/{pid}`.
  """
  @spec states_broadcast!(Event.t(), pid()) :: :ok
  def states_broadcast!(event, pid) do
    impl().states_broadcast!(event, pid)
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

    def general_broadcast!(event) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/*", event)
    end

    def general_broadcast!(event, pid) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/*", event)
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/#{pid}", event)
    end

    def traces_broadcast!(event) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/*", event)
    end

    def traces_broadcast!(event, pid) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/*", event)
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/#{pid}", event)
    end

    def states_broadcast!(event) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/*", event)
    end

    def states_broadcast!(event, pid) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/*", event)
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/#{pid}", event)
    end
  end
end
