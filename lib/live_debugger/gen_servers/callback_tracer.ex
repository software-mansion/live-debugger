defmodule LiveDebugger.GenServers.CallbackTracer do
  use GenServer

  require Logger

  alias LiveDebugger.Services.ModuleDiscoveryService
  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils
  alias LiveDebugger.Structs.Trace

  @callbacks_functions CallbackUtils.callbacks_functions() ++ [:test]

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def pause_tracing() do
    GenServer.call(__MODULE__, :pause_tracing)
  end

  def continue_tracing() do
    GenServer.call(__MODULE__, :continue_tracing)
  end

  def test() do
    :ok
  end

  @impl true
  def init(_args) do
    {:ok, [], {:continue, :setup_tracing}}
  end

  @impl true
  def handle_continue(:setup_tracing, state) do
    :dbg.tracer(:process, {&trace_handler/2, 0})
    :dbg.p(:all, :c)

    all_modules = ModuleDiscoveryService.all_modules()

    callbacks =
      all_modules
      |> ModuleDiscoveryService.live_view_modules()
      |> CallbackUtils.live_view_callbacks()

    all_modules
    |> ModuleDiscoveryService.live_component_modules()
    |> CallbackUtils.live_component_callbacks()
    |> Enum.concat(callbacks)
    |> Enum.map(fn mfa -> :dbg.tp(mfa, []) end)

    :dbg.tp({Phoenix.LiveView.Channel, :handle_info, 2}, [])
    :dbg.tp({LiveDebugger.GenServers.CallbackTracer, :test, 0}, [])

    {:noreply, state}
  end

  @impl true
  def handle_call(:pause_tracing, _from, state) do
    :dbg.p(:all, :clear)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:continue_tracing, _from, state) do
    :dbg.p(:all, :c)

    {:reply, :ok, state}
  end

  # These are not callbacks created by user
  # We trace channel events to refresh the components tree
  defp trace_handler({_, pid, _, {Phoenix.LiveView.Channel, :handle_info, [msg, _] = args}}, n) do
    case msg do
      %{event: "cids_destroyed"} ->
        trace = Trace.new(n, Phoenix.LiveView.Channel, :handle_info, args, pid)

      _ ->
        nil
    end

    n - 1
  end

  defp trace_handler({_, pid, _, {module, fun, args}}, n) when fun in @callbacks_functions do
    trace = Trace.new(n, module, fun, args, pid)

    n - 1
  end

  defp trace_handler(trace, n) do
    Logger.info("Ignoring unexpected trace: #{inspect(trace)}")
    n
  end
end
