defmodule LiveDebugger.Services.CallbackTracer.GenServers.TracingManager do
  @moduledoc """
  Manages the tracing of callbacks.
  """

  use GenServer

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.UserChangedSettings
  alias LiveDebugger.App.Events.UserRefreshedTrace

  alias LiveDebugger.Services.CallbackTracer.Actions.Tracing, as: TracingActions

  @tracing_setup_delay Application.compile_env(:live_debugger, :tracing_setup_delay, 0)

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
  def init(opts) do
    Bus.receive_events!()
    Process.send_after(self(), :setup_tracing, @tracing_setup_delay)

    {:ok, opts}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  @impl true
  def handle_info(:setup_tracing, state) do
    TracingActions.setup_tracing!()

    {:noreply, state}
  end

  @impl true
  def handle_info(%UserChangedSettings{key: :tracing_update_on_code_reload, value: true}, state) do
    TracingActions.start_tracing_recompile_pattern()

    {:noreply, state}
  end

  @impl true
  def handle_info(%UserChangedSettings{key: :tracing_update_on_code_reload, value: false}, state) do
    TracingActions.stop_tracing_recompile_pattern()

    {:noreply, state}
  end

  @impl true
  def handle_info(%UserRefreshedTrace{}, state) do
    TracingActions.refresh_tracing()

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
