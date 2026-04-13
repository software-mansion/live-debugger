defmodule LiveDebugger.Services.CallbackTracer.GenServers.TracingManager do
  @moduledoc """
  Manages the tracing of callbacks.
  """

  use GenServer

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.UserRefreshedTrace
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.Services.CallbackTracer.Events.DbgKilled

  alias LiveDebugger.Services.CallbackTracer.Actions.Tracing, as: TracingActions

  @type state() :: %{dbg_pid: pid() | nil}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Checks if GenServer has been loaded
  """
  def ping!() do
    GenServer.call(__MODULE__, :ping)
  end

  @doc """
  Checks if tracing is currently started
  """
  def tracing_started?() do
    GenServer.call(__MODULE__, :tracing_started?, 10000)
  end

  @impl true
  def init(_opts) do
    Bus.receive_events!()

    :net_kernel.monitor_nodes(true, %{node_type: :visible})

    {:ok, %{dbg_pid: nil}, {:continue, :setup_tracing}}
  end

  @impl true
  def handle_continue(:setup_tracing, state) do
    new_state = TracingActions.setup_tracing_with_monitoring!(state)

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  def handle_call(:tracing_started?, _from, state) do
    {:reply, state.dbg_pid != nil, state}
  end

  @impl true
  def handle_info(event, state) when event in [:refresh_tracing, %UserRefreshedTrace{}] do
    state
    |> TracingActions.setup_tracing_with_monitoring!()
    |> then(&{:noreply, &1})
  end

  def handle_info(%LiveViewBorn{pid: pid}, state) do
    TracingActions.start_outgoing_messages_tracing(pid)

    {:noreply, state}
  end

  def handle_info({:file_event, _pid, {path, events}}, state) do
    if correct_event?(events) do
      TracingActions.refresh_tracing(path)
    end

    {:noreply, state}
  end

  # handling dbg tracer stop
  def handle_info({:DOWN, _, _, pid, :done}, %{dbg_pid: pid} = state) do
    Bus.broadcast_event!(%DbgKilled{})

    {:noreply, %{state | dbg_pid: nil}}
  end

  def handle_info({:nodeup, _name, _}, state) do
    send(self(), :refresh_tracing)

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp correct_event?(events) do
    Enum.any?(events, &(&1 == :modified || &1 == :created))
  end
end
