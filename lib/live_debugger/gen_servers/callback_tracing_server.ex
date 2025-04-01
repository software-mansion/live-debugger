defmodule LiveDebugger.GenServers.CallbackTracingServer do
  @moduledoc """
  This gen_server is responsible for tracing the callbacks of the LiveView processes.
  """

  use GenServer

  require Logger

  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Services.ModuleDiscoveryService
  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Services.System.ProcessService
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  @callback_functions CallbackUtils.callbacks_functions()

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, [], {:continue, :setup_tracing}}
  end

  @impl true
  def handle_continue(:setup_tracing, state) do
    # TODO check with Node.alive?()
    Process.sleep(500)
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
    |> Enum.each(fn mfa -> :dbg.tp(mfa, []) end)

    # These are not callbacks created by user
    # We trace channel events to refresh the components tree
    :dbg.tp({Phoenix.LiveView.Diff, :delete_component, 2}, [])

    # Write component is not perfect - it is triggered on send(self()) but it is better than tracing renders
    :dbg.tp({Phoenix.LiveView.Diff, :write_component, 4}, [])

    {:noreply, state}
  end

  # This handler is heavy because of fetching state and we do not care for order because it is no displayed to user
  # Because of that we do it asynchronously to speed up tracer a bit
  defp trace_handler({_, pid, _, {Phoenix.LiveView.Diff, :delete_component, [cid | _] = args}}, n) do
    Task.start(fn ->
      with cid <- %Phoenix.LiveComponent.CID{cid: cid},
           {:ok, %{socket: %{id: socket_id, transport_pid: transport_pid}}} <-
             ProcessService.state(pid),
           true <- is_pid(transport_pid),
           trace <-
             Trace.new(
               n,
               Phoenix.LiveView.Diff,
               :delete_component,
               args,
               socket_id,
               transport_pid,
               pid,
               cid
             ) do
        publish_trace(trace)
      end
    end)

    n
  end

  defp trace_handler({_, pid, _, {Phoenix.LiveView.Diff, :write_component, args}}, n) do
    Task.start(fn ->
      with trace <- Trace.new(n, Phoenix.LiveView.Diff, :write_component, args, pid),
           true <- is_pid(trace.transport_pid) do
        publish_trace(trace)
      end
    end)

    n
  end

  defp trace_handler({_, pid, _, {module, fun, args}}, n) when fun in @callback_functions do
    with trace <- Trace.new(n, module, fun, args, pid),
         true <- is_pid(trace.transport_pid),
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
    trace.transport_pid
    |> TraceService.ets_table_id(trace.socket_id)
    |> TraceService.insert(trace.id, trace)

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

  defp do_publish(%{module: Phoenix.LiveView.Diff} = _trace) do
    # socket_id = trace.socket_id
    :ok

    # PubSub.broadcast!(LiveDebugger.PubSub, "#{socket_id}/*/tree_updated", {:new_trace, trace})
  end

  defp do_publish(trace) do
    socket_id = trace.socket_id
    node_id = inspect(Trace.node_id(trace))
    transport_pid = inspect(trace.transport_pid)
    fun = inspect(trace.function)

    PubSubUtils.broadcast(
      [
        "#{socket_id}/#{transport_pid}/#{node_id}/#{fun}",
        "#{socket_id}/#{transport_pid}/#{node_id}/*",
        "#{socket_id}/#{transport_pid}/*/*"
      ],
      {:new_trace, trace}
    )
  end
end
