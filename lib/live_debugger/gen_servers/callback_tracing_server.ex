defmodule LiveDebugger.GenServers.CallbackTracingServer do
  @moduledoc """
  This gen_server is responsible for tracing callbacks.
  """

  use GenServer

  require Logger

  alias LiveDebugger.Services.System.DbgService, as: Dbg
  alias LiveDebugger.Services.ModuleDiscoveryService
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  @callback_functions CallbackUtils.callbacks_functions()

  ## API

  @doc """
  Checks if GenServer has been loaded
  """
  @spec ping!() :: :ok
  def ping!() do
    GenServer.call(__MODULE__, :ping)
  end

  ## GenServer

  @doc false
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    tracing_setup_delay = Application.get_env(:live_debugger, :tracing_setup_delay, 0)
    Process.send_after(self(), :setup_tracing, tracing_setup_delay)

    {:ok, %{}}
  end

  @impl true
  def handle_info(:setup_tracing, state) do
    Dbg.tracer(:process, {&handle_trace/2, 0})
    Dbg.p(:all, [:c, :timestamp])

    all_modules = ModuleDiscoveryService.all_modules()

    callbacks =
      all_modules
      |> ModuleDiscoveryService.live_view_modules()
      |> CallbackUtils.live_view_callbacks()

    all_modules
    |> ModuleDiscoveryService.live_component_modules()
    |> CallbackUtils.live_component_callbacks()
    |> Enum.concat(callbacks)
    |> Enum.each(fn mfa ->
      Dbg.tp(mfa, [{:_, [], [{:return_trace}]}])
      Dbg.tp(mfa, [{:_, [], [{:exception_trace}]}])
    end)

    # This is not a callback created by user
    # We trace it to refresh the components tree
    Dbg.tp({Phoenix.LiveView.Diff, :delete_component, 2}, [])

    {:noreply, state}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, :ok, state}
  end

  # This handler is heavy because of fetching state and we do not care for order because it is not displayed to user
  # Because of that we do it asynchronously to speed up tracer a bit
  # We do not persist this trace because it is not displayed to user
  @spec handle_trace(term(), n :: integer()) :: integer()
  defp handle_trace(
         {_, pid, _, {Phoenix.LiveView.Diff, :delete_component, [cid | _] = args}, _},
         n
       ) do
    Task.start(fn ->
      with cid <- %Phoenix.LiveComponent.CID{cid: cid},
           {:ok, %{socket: socket}} <- ChannelService.state(pid),
           %{id: socket_id, transport_pid: transport_pid} <- socket,
           true <- is_pid(transport_pid),
           trace <-
             Trace.new(
               n,
               Phoenix.LiveView.Diff,
               :delete_component,
               args,
               pid,
               socket_id: socket_id,
               transport_pid: transport_pid,
               cid: cid
             ) do
        publish_trace(trace)
      end
    end)

    n
  end

  # This handles callbacks created by user that will be displayed to user
  # It cannot be async because we care about order
  defp handle_trace({_, pid, :call, {module, fun, args}, timestamp}, n)
       when fun in @callback_functions do
    with trace <- Trace.new(n, module, fun, args, pid),
         true <- is_pid(trace.transport_pid),
         :ok <- persist_trace(trace) do
      :erlang.put({pid, module, fun}, {timestamp, trace})
      publish_trace(trace)
    end

    n - 1
  end

  defp handle_trace({_, pid, :return_from, {module, fun, _arity}, _, return_ts}, n)
       when fun in @callback_functions do
    with {call_ts, trace} <- :erlang.get({pid, module, fun}),
         execution_time <- :timer.now_diff(return_ts, call_ts),
         trace <- %{trace | execution_time: execution_time},
         :ok <- persist_trace(trace) do
      :erlang.erase({pid, module, fun})
      publish_update_trace(trace)
    end

    n
  end

  defp handle_trace({_, _pid, :exception_from, {_module, fun, _}, _, _timestamp}, n)
       when fun in @callback_functions do
    n
  end

  defp handle_trace(trace, n) do
    Logger.info("Ignoring unexpected trace: #{inspect(trace)}")
    n
  end

  @spec persist_trace(Trace.t()) :: :ok | {:error, term()}
  defp persist_trace(%Trace{} = trace) do
    TraceService.insert(trace)

    :ok
  rescue
    err ->
      Logger.error("Error while persisting trace: #{inspect(err)}")
      {:error, err}
  end

  @spec publish_trace(Trace.t()) :: :ok | {:error, term()}
  defp publish_trace(%Trace{} = trace) do
    do_publish(trace)
    :ok
  rescue
    err ->
      Logger.error("Error while publishing trace: #{inspect(err)}")
      {:error, err}
  end

  @spec publish_update_trace(Trace.t()) :: :ok | {:error, term()}
  defp publish_update_trace(%Trace{} = trace) do
    do_publish_update(trace)
    :ok
  rescue
    err ->
      Logger.error("Error while publishing trace: #{inspect(err)}")
      {:error, err}
  end

  @spec do_publish(Trace.t()) :: :ok
  defp do_publish(%{module: Phoenix.LiveView.Diff} = trace) do
    trace
    |> PubSubUtils.component_deleted_topic()
    |> PubSubUtils.broadcast({:new_trace, trace})
  end

  defp do_publish(trace) do
    socket_id = trace.socket_id
    node_id = Trace.node_id(trace)
    transport_pid = trace.transport_pid
    fun = trace.function

    socket_id
    |> PubSubUtils.tsnf_topic(transport_pid, node_id, fun)
    |> PubSubUtils.broadcast({:new_trace, trace})

    socket_id
    |> PubSubUtils.ts_f_topic(transport_pid, fun)
    |> PubSubUtils.broadcast({:new_trace, trace})
  end

  @spec do_publish_update(Trace.t()) :: :ok
  defp do_publish_update(trace) do
    socket_id = trace.socket_id
    node_id = Trace.node_id(trace)
    transport_pid = trace.transport_pid
    fun = trace.function

    socket_id
    |> PubSubUtils.tsnf_topic(transport_pid, node_id, fun)
    |> PubSubUtils.broadcast({:updated_trace, trace})
  end
end
