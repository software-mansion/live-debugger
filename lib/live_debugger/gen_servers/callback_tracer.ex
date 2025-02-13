defmodule LiveDebugger.GenServers.CallbackTracer do
  use GenServer

  require Logger

  alias LiveDebugger.Services.System.ProcessService
  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Services.ModuleDiscoveryService
  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils
  alias LiveDebugger.Structs.Trace

  alias Phoenix.PubSub

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

    :dbg.tp({LiveDebugger.GenServers.CallbackTracer, :test, 0}, [])

    # These are not callbacks created by user
    # We trace channel events to refresh the components tree
    :dbg.tp({Phoenix.LiveView.Diff, :delete_component, 2}, [])

    # Write component is not perfect - it is triggered on send(self()) but it is better than tracing renders
    :dbg.tp({Phoenix.LiveView.Diff, :write_component, 4}, [])

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

  # This handler is heavy because of fetching state and we do not care for order because it is no displayed to user
  # Because of that we do it asynchronously to speed up tracer a bit
  defp trace_handler({_, pid, _, {Phoenix.LiveView.Diff, :delete_component, [cid | _] = args}}, n) do
    Task.start(fn ->
      with cid <- %Phoenix.LiveComponent.CID{cid: cid},
           {:ok, %{socket: %{id: socket_id}}} <- ProcessService.state(pid) do
        n
        |> Trace.new(Phoenix.LiveView.Diff, :delete_component, args, socket_id, pid, cid)
        |> publish_trace()
      end
    end)

    n
  end

  defp trace_handler({_, pid, _, {Phoenix.LiveView.Diff, :write_component, args}}, n) do
    Task.start(fn ->
      n
      |> Trace.new(Phoenix.LiveView.Diff, :write_component, args, pid)
      |> publish_trace()
    end)

    n
  end

  defp trace_handler({_, pid, _, {module, fun, args}}, n) when fun in @callbacks_functions do
    with trace <- Trace.new(n, module, fun, args, pid),
         :ok <- persist_trace(trace) do
      publish_trace(trace)
    end

    n - 1
  end

  defp trace_handler(trace, n) do
    Logger.info("Ignoring unexpected trace: #{inspect(trace)}")
    n
  end

  defp persist_trace(trace) do
    TraceService.insert(trace)
    :ok
  rescue
    err ->
      Logger.error("Error while persisting trace: #{inspect(err)}")
      {:error, err}
  end

  defp publish_trace(%Trace{} = trace) do
    do_publish(trace)
    :ok
  rescue
    err ->
      Logger.error("Error while publishing trace: #{inspect(err)}")
      {:error, err}
  end

  defp do_publish(%{module: module} = trace)
       when module in [Phoenix.LiveView.Channel, Phoenix.LiveView.Diff] do
    socket_id = trace.socket_id

    PubSub.broadcast!(LiveDebugger.PubSub, "#{socket_id}/*/tree_updated", {:new_trace, trace})
  end

  defp do_publish(trace) do
    socket_id = trace.socket_id
    node_id = inspect(Trace.node_id(trace))
    fun = inspect(trace.function)

    PubSub.broadcast!(LiveDebugger.PubSub, "#{socket_id}/#{node_id}/#{fun}", {:new_trace, trace})
    PubSub.broadcast!(LiveDebugger.PubSub, "#{socket_id}/#{node_id}/*", {:new_trace, trace})
    PubSub.broadcast!(LiveDebugger.PubSub, "#{socket_id}/*/*", {:new_trace, trace})
  end
end
