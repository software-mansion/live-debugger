defmodule LiveDebugger.Services.CallbackTracer.GenServers.TracingManager do
  @moduledoc """
  Manages the tracing of callbacks.

  In `:ip` port mode, the monitored pid (`:dbg_pid` for historical reasons)
  is the `:dbg.trace_client` process, not the producer-side tracer port.
  The client is the one we care about: if it dies, decoded traces stop
  reaching `TraceHandler`, regardless of whether the C-side port is alive.
  """

  use GenServer

  alias LiveDebugger.API.System.Dbg
  alias LiveDebugger.App.Events.UserRefreshedTrace
  alias LiveDebugger.Services.CallbackTracer.Actions.Tracing, as: TracingActions

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.DbgKilled
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn

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

  @impl true
  def init(_opts) do
    Bus.receive_events!()
    # Ensure no tracer is running (GenServer restart)
    Dbg.stop()

    :net_kernel.monitor_nodes(true, %{node_type: :visible})

    {:ok, %{tracer_pid: nil, trace_client_pid: nil}, {:continue, :setup_tracing}}
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

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:refresh_tracing, state) do
    state = TracingActions.setup_tracing_with_monitoring!(state)

    {:noreply, state}
  end

  def handle_info(%UserRefreshedTrace{}, state) do
    state = TracingActions.setup_tracing_with_monitoring!(state)

    {:noreply, state}
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

  # The monitored pid is the trace_client. Any exit reason (`:done`,
  # `:killed` from the heap-size flag, connection loss, etc.) means traces
  # have stopped flowing — broadcast `DbgKilled` so subscribers can react.
  def handle_info({:DOWN, _, _, pid, _reason}, %{tracer_pid: pid} = state) do
    Bus.broadcast_event!(%DbgKilled{})

    {:noreply, %{state | tracer_pid: nil}}
  end

  def handle_info({:DOWN, _, _, pid, _reason}, %{trace_client_pid: pid} = state) do
    Bus.broadcast_event!(%DbgKilled{})

    {:noreply, %{state | trace_client_pid: nil}}
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
