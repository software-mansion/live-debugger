defmodule LiveDebugger.Services.CallbackTracer.GenServers.TracingManager do
  @moduledoc """
  Manages the tracing of callbacks.
  """

  use GenServer

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.UserRefreshedTrace
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn

  alias LiveDebugger.Services.CallbackTracer.Actions.Tracing, as: TracingActions

  @telemetry_event_name [:phoenix, :live_view, :render, :stop]

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
    TracingActions.monitor_recompilation()
    attach_telemetry_handler()

    send(self(), :setup_tracing)

    {:ok, %{dbg_pid: nil}}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  @impl true
  def handle_info(:setup_tracing, state) do
    new_state = TracingActions.setup_tracing!(state)

    {:noreply, new_state}
  end

  def handle_info(:refresh_tracing, state) do
    TracingActions.refresh_tracing()

    {:noreply, state}
  end

  def handle_info(%LiveViewBorn{pid: pid}, state) do
    TracingActions.start_outgoing_messages_tracing(pid)

    {:noreply, state}
  end

  def handle_info(%UserRefreshedTrace{}, state) do
    TracingActions.refresh_tracing()

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
    send(self(), :setup_tracing)

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def handle_telemetry(@telemetry_event_name, _measurements, metadata, manager_pid) do
    if not LiveDebugger.Utils.Modules.debugger_module?(metadata.socket.endpoint) do
      send(manager_pid, :refresh_tracing)

      :telemetry.detach({__MODULE__, @telemetry_event_name, manager_pid})
    end
  end

  defp attach_telemetry_handler() do
    :telemetry.attach(
      {__MODULE__, @telemetry_event_name, self()},
      @telemetry_event_name,
      &__MODULE__.handle_telemetry/4,
      self()
    )
  end

  defp correct_event?(events) do
    Enum.any?(events, &(&1 == :modified || &1 == :created))
  end
end
