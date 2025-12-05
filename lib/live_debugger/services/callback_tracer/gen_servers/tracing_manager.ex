defmodule LiveDebugger.Services.CallbackTracer.GenServers.TracingManager do
  @moduledoc """
  Manages the tracing of callbacks.
  """

  use GenServer

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.UserRefreshedTrace
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.API.System.Module, as: ModuleAPI
  alias LiveDebugger.Utils.Modules, as: UtilsModules

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

  def handle_info(%LiveViewBorn{pid: pid}, state) do
    TracingActions.start_outgoing_messages_tracing(pid)

    {:noreply, state}
  end

  def handle_info(%UserRefreshedTrace{}, state) do
    TracingActions.refresh_tracing()

    {:noreply, state}
  end

  def handle_info({:file_event, _pid, {path, events}}, state) do
    with true <- correct_event?(events),
         true <- beam_file?(path),
         module <- path |> Path.basename(".beam") |> String.to_existing_atom(),
         true <- ModuleAPI.loaded?(module),
         false <- UtilsModules.debugger_module?(module),
         true <- live_module?(module) do
      dbg(module)
      TracingActions.refresh_tracing(module)
    end

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp correct_event?(events) do
    Enum.any?(events, &(&1 == :modified || &1 == :created))
  end

  defp beam_file?(path) do
    String.ends_with?(path, ".beam")
  end

  defp live_module?(module) do
    module
    |> ModuleAPI.behaviours()
    |> Enum.any?(&(&1 == Phoenix.LiveView || &1 == Phoenix.LiveComponent))
  end
end
