defmodule LiveDebugger.GenServers.CallbackTracingServer do
  @moduledoc """
  This gen_server is responsible for tracing callbacks.
  """

  use GenServer

  require Logger

  alias LiveDebugger.GenServers.SettingsServer
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
  @spec ping!() :: :pong
  def ping!() do
    GenServer.call(__MODULE__, :ping)
  end

  @spec add_code_reload_tracing() :: :ok
  def add_code_reload_tracing() do
    Dbg.tp({Mix.Tasks.Compile.Elixir, :run, 1}, [{:_, [], [{:return_trace}]}])
    :ok
  end

  @spec remove_code_reload_tracing() :: :ok
  def remove_code_reload_tracing() do
    Dbg.ctp({Mix.Tasks.Compile.Elixir, :run, 1})
    :ok
  end

  @doc """
  Refreshes list of traced LiveView modules' callbacks.
  It is necessary when hot reloading of code is being used.
  """
  @spec update_traced_modules() :: :ok
  def update_traced_modules() do
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

    :ok
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
  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  @impl true
  def handle_info(:setup_tracing, state) do
    Dbg.tracer(:process, {&handle_trace/2, 0})
    Dbg.p(:all, [:c, :timestamp])

    update_traced_modules()

    if SettingsServer.get(:tracing_update_on_code_reload) do
      add_code_reload_tracing()
    end

    # This is not a callback created by user
    # We trace it to refresh the components tree
    Dbg.tp({Phoenix.LiveView.Diff, :delete_component, 2}, [])

    {:noreply, state}
  end

  @spec handle_trace(term(), n :: integer()) :: integer()
  defp handle_trace({_, _, :return_from, {Mix.Tasks.Compile.Elixir, _, _}, {:ok, _}, _}, n) do
    Process.sleep(100)
    update_traced_modules()
    n
  end

  defp handle_trace({_, _, _, {Mix.Tasks.Compile.Elixir, _, _}, _}, n) do
    n
  end

  defp handle_trace({_, _, _, {Mix.Tasks.Compile.Elixir, _, _}, _, _}, n) do
    n
  end

  # This handler is heavy because of fetching state and we do not care for order because it is not displayed to user
  # Because of that we do it asynchronously to speed up tracer a bit
  # We do not persist this trace because it is not displayed to user
  defp handle_trace(
         {_, pid, _, {Phoenix.LiveView.Diff, :delete_component, [cid | _] = args}, timestamp},
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
               timestamp,
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
    with trace <- Trace.new(n, module, fun, args, pid, timestamp),
         true <- is_pid(trace.transport_pid),
         :ok <- persist_trace(trace) do
      :erlang.put({pid, module, fun}, {timestamp, trace})
      publish_trace(trace)
    end

    n - 1
  end

  defp handle_trace({_, pid, type, {module, fun, _arity}, _, return_ts}, n)
       when fun in @callback_functions and type in [:return_from, :exception_from] do
    with {call_ts, trace} <- :erlang.get({pid, module, fun}),
         execution_time <- :timer.now_diff(return_ts, call_ts),
         trace <- %{trace | execution_time: execution_time, type: type},
         :ok <- persist_trace(trace) do
      :erlang.erase({pid, module, fun})
      publish_update_trace(trace)
    end

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
      Logger.error("Error while publishing update trace: #{inspect(err)}")
      {:error, err}
  end

  @spec do_publish(Trace.t()) :: :ok
  defp do_publish(%{module: Phoenix.LiveView.Diff} = trace) do
    PubSubUtils.component_deleted_topic()
    |> PubSubUtils.broadcast({:component_deleted, trace})
  end

  defp do_publish(%Trace{} = trace) do
    pid = trace.pid
    node_id = Trace.node_id(trace)

    fun = trace.function

    pid
    |> PubSubUtils.trace_topic_per_node(node_id, fun, :call)
    |> PubSubUtils.broadcast({:new_trace, trace})

    pid
    |> PubSubUtils.trace_topic_per_pid(fun, :call)
    |> PubSubUtils.broadcast({:new_trace, trace})
  end

  @spec do_publish_update(Trace.t()) :: :ok
  defp do_publish_update(trace) do
    pid = trace.pid
    node_id = Trace.node_id(trace)
    fun = trace.function

    if fun == :render do
      PubSubUtils.node_rendered_topic()
      |> PubSubUtils.broadcast({:render_trace, trace})
    end

    pid
    |> PubSubUtils.trace_topic_per_node(node_id, fun, :return)
    |> PubSubUtils.broadcast({:updated_trace, trace})

    pid
    |> PubSubUtils.trace_topic_per_pid(fun, :return)
    |> PubSubUtils.broadcast({:updated_trace, trace})
  end
end
