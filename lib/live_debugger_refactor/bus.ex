defmodule LiveDebuggerRefactor.Bus do
  @moduledoc """
  Bus is a module that provides a way to send events to the LiveDebugger.
  """

  alias LiveDebuggerRefactor.Event

  @pubsub_name Application.compile_env(:live_debugger, :pubsub_name, LiveDebugger.PubSub)

  @doc """
  Appends the pubsub child to the list of children.
  """
  @spec append_pubsub_children(children :: list()) :: list()
  def append_pubsub_children(children) do
    [{Phoenix.PubSub, name: @pubsub_name} | children]
  end

  @doc """
  Broadcast event to general topic `lvdbg/*`.
  """
  @spec general_broadcast!(Event.t()) :: :ok
  def general_broadcast!(event) do
    Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/*", event)
  end

  @doc """
  Broadcast event to general topic with specific pid `lvdbg/\#{pid}`.
  """
  @spec general_broadcast!(Event.t(), pid()) :: :ok
  def general_broadcast!(event, pid) do
    Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/#{pid}", event)
  end

  @doc """
  Broadcast event to traces topic `lvdbg/traces/*`.
  """
  @spec traces_broadcast!(Event.t()) :: :ok
  def traces_broadcast!(event) do
    Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/*", event)
  end

  @doc """
  Broadcast event to traces topic with specific pid `lvdbg/traces/\#{pid}`.
  """
  @spec traces_broadcast!(Event.t(), pid()) :: :ok
  def traces_broadcast!(event, pid) do
    Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/#{pid}", event)
  end

  @doc """
  Broadcast event to states topic `lvdbg/states/*`.
  """
  @spec states_broadcast!(Event.t()) :: :ok
  def states_broadcast!(event) do
    Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/*", event)
  end

  @doc """
  Broadcast event to states topic with specific pid `lvdbg/states/\#{pid}`.
  """
  @spec states_broadcast!(Event.t(), pid()) :: :ok
  def states_broadcast!(event, pid) do
    Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/#{pid}", event)
  end
end
