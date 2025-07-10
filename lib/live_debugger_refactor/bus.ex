defmodule LiveDebuggerRefactor.Bus do
  @moduledoc """
  This module is responsible for broadcasting events inside LiveDebugger.

  Bus is built on top of Phoenix.PubSub. It uses 3 types of topics:
  - `lvdbg/*` - general topic used to broadcast general events to all processes.
  - `lvdbg/traces/*` - traces topic used to broadcast traces to all processes.
  - `lvdbg/states/*` - states topic used to broadcast states to all processes.

  The `*` in the topic is a wildcard. It can be replaced with pid of debugged process or debugger LiveView depending on the event type.

  It needs to be added to the supervision tree of the application using `append_bus_tree/1` function.
  """

  alias LiveDebuggerRefactor.Event

  @callback append_bus_tree(children :: list()) :: list()

  @callback broadcast_event!(Event.t()) :: :ok
  @callback broadcast_event!(Event.t(), pid()) :: :ok
  @callback broadcast_trace!(Event.t()) :: :ok
  @callback broadcast_trace!(Event.t(), pid()) :: :ok
  @callback broadcast_state!(Event.t()) :: :ok
  @callback broadcast_state!(Event.t(), pid()) :: :ok

  @callback receive_events() :: :ok | {:error, term()}
  @callback receive_events(pid()) :: :ok | {:error, term()}
  @callback receive_traces() :: :ok | {:error, term()}
  @callback receive_traces(pid()) :: :ok | {:error, term()}
  @callback receive_states() :: :ok | {:error, term()}
  @callback receive_states(pid()) :: :ok | {:error, term()}

  @doc """
  Appends the bus children to the supervision tree.
  """
  @spec append_bus_tree(children :: list()) :: list()
  def append_bus_tree(children) do
    impl().append_bus_tree(children)
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
  def broadcast_event!(event, pid) when is_pid(pid) do
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
  def broadcast_trace!(event, pid) when is_pid(pid) do
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
  def broadcast_state!(event, pid) when is_pid(pid) do
    impl().broadcast_state!(event, pid)
  end

  @doc """
  Receive events from general topic: `lvdbg/*`.
  """
  @spec receive_events() :: :ok | {:error, term()}
  def receive_events() do
    impl().receive_events()
  end

  @doc """
  Receive events from general topic with specific pid: `lvdbg/{pid}`.
  """
  @spec receive_events(pid()) :: :ok | {:error, term()}
  def receive_events(pid) when is_pid(pid) do
    impl().receive_events(pid)
  end

  @doc """
  Receive traces from traces topic: `lvdbg/traces/*`.
  """
  @spec receive_traces() :: :ok | {:error, term()}
  def receive_traces() do
    impl().receive_traces()
  end

  @doc """
  Receive traces from traces topic with specific pid: `lvdbg/traces/{pid}`.
  """
  @spec receive_traces(pid()) :: :ok | {:error, term()}
  def receive_traces(pid) when is_pid(pid) do
    impl().receive_traces(pid)
  end

  @doc """
  Receive states from states topic: `lvdbg/states/*`.
  """
  @spec receive_states() :: :ok | {:error, term()}
  def receive_states() do
    impl().receive_states()
  end

  @doc """
  Receive states from states topic with specific pid: `lvdbg/states/{pid}`.
  """
  @spec receive_states(pid()) :: :ok | {:error, term()}
  def receive_states(pid) when is_pid(pid) do
    impl().receive_states(pid)
  end

  defp impl() do
    Application.get_env(:live_debugger, :bus, __MODULE__.Impl)
  end

  defmodule Impl do
    @moduledoc false

    @behaviour LiveDebuggerRefactor.Bus

    @pubsub_name Application.compile_env(
                   :live_debugger,
                   :pubsub_name,
                   LiveDebuggerRefactor.PubSub
                 )

    @impl true
    def append_bus_tree(children) do
      [{Phoenix.PubSub, name: @pubsub_name} | children]
    end

    @impl true
    def broadcast_event!(event) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/*", event)
    end

    @impl true
    def broadcast_event!(event, pid) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/*", event)
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/#{inspect(pid)}", event)
    end

    @impl true
    def broadcast_trace!(event) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/*", event)
    end

    @impl true
    def broadcast_trace!(event, pid) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/*", event)
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/traces/#{inspect(pid)}", event)
    end

    @impl true
    def broadcast_state!(event) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/*", event)
    end

    @impl true
    def broadcast_state!(event, pid) do
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/*", event)
      Phoenix.PubSub.broadcast!(@pubsub_name, "lvdbg/states/#{inspect(pid)}", event)
    end

    @impl true
    def receive_events() do
      Phoenix.PubSub.subscribe(@pubsub_name, "lvdbg/*")
    end

    @impl true
    def receive_events(pid) do
      Phoenix.PubSub.subscribe(@pubsub_name, "lvdbg/#{inspect(pid)}")
    end

    @impl true
    def receive_traces() do
      Phoenix.PubSub.subscribe(@pubsub_name, "lvdbg/traces/*")
    end

    @impl true
    def receive_traces(pid) do
      Phoenix.PubSub.subscribe(@pubsub_name, "lvdbg/traces/#{inspect(pid)}")
    end

    @impl true
    def receive_states() do
      Phoenix.PubSub.subscribe(@pubsub_name, "lvdbg/states/*")
    end

    @impl true
    def receive_states(pid) do
      Phoenix.PubSub.subscribe(@pubsub_name, "lvdbg/states/#{inspect(pid)}")
    end
  end
end
