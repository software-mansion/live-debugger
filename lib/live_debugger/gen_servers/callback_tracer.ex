defmodule LiveDebugger.GenServers.CallbackTracer do
  use GenServer

  alias LiveDebugger.Services.ModuleDiscoveryService
  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def pause_tracing() do
    GenServer.call(__MODULE__, :pause_tracing)
  end

  def continue_tracing() do
    GenServer.call(__MODULE__, :continue_tracing)
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

    :dbg.tp({Phoenix.LiveView.Diff, :delete_component, 2}, [])

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

  defp trace_handler(msg, n) do
    dbg({msg, n})

    n - 1
  end
end
