defmodule LiveDebugger.GenServers.CallbackTracingServer do
  @moduledoc """
  This gen_server is responsible for tracing callbacks and managing ETS tables.
  """

  use GenServer

  require Logger

  alias LiveDebugger.Services.{ModuleDiscoveryService, ChannelService, TraceService}
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  @ets_table_name :lvdbg_traces
  @callback_functions CallbackUtils.callbacks_functions()

  @type table_refs() :: %{pid() => :ets.table()}

  ## API

  @doc """
  Returns ETS table reference.
  It creates table if none is associated with given pid
  """
  @spec table(pid :: pid()) :: :ets.table()
  def table(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:get_or_create_table, pid}, 1000)
  end

  @doc """
  If table for given `pid` exists it deletes it from ETS.
  """
  @spec delete_table(pid :: pid()) :: :ok
  def delete_table(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:delete_table, pid}, 1000)

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
  def handle_info(:setup_tracing, table_refs) do
    :dbg.tracer(:process, {&handle_trace/2, 0})
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

    # This is not a callback created by user
    # We trace it to refresh the components tree
    :dbg.tp({Phoenix.LiveView.Diff, :delete_component, 2}, [])

    {:noreply, table_refs}
  end

  def handle_info({:DOWN, _, :process, closed_pid, _}, table_refs) do
    {_, table_refs} = delete_ets_table(closed_pid, table_refs)

    closed_pid
    |> PubSubUtils.process_status_topic()
    |> PubSubUtils.broadcast({:process_status, :dead})

    {:noreply, table_refs}
  end

  @impl true
  def handle_call({:get_or_create_table, pid}, _from, table_refs) do
    if ref = Map.get(table_refs, pid) do
      {:reply, ref, table_refs}
    else
      ref = create_ets_table()
      Process.monitor(pid)
      {:reply, ref, Map.put(table_refs, pid, ref)}
    end
  end

  def handle_call({:delete_table, pid}, _from, table_refs) do
    {_, table_refs} = delete_ets_table(pid, table_refs)
    {:reply, :ok, table_refs}
  end

  @spec create_ets_table() :: :ets.table()
  defp create_ets_table() do
    :ets.new(@ets_table_name, [:ordered_set, :public])
  end

  @spec delete_ets_table(pid(), table_refs()) :: {boolean(), table_refs()}
  defp delete_ets_table(pid, table_refs) do
    case Map.pop(table_refs, pid) do
      {nil, table_refs} ->
        {false, table_refs}

      {ref, updated_table_refs} ->
        :ets.delete(ref)
        {true, updated_table_refs}
    end
  end

  # This handler is heavy because of fetching state and we do not care for order because it is not displayed to user
  # Because of that we do it asynchronously to speed up tracer a bit
  # We do not persist this trace because it is not displayed to user
  @spec handle_trace(term(), n :: integer()) :: integer()
  defp handle_trace({_, pid, _, {Phoenix.LiveView.Diff, :delete_component, [cid | _] = args}}, n) do
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
  defp handle_trace({_, pid, _, {module, fun, args}}, n) when fun in @callback_functions do
    with trace <- Trace.new(n, module, fun, args, pid),
         true <- is_pid(trace.transport_pid),
         :ok <- persist_trace(trace) do
      publish_trace(trace)
    end

    n - 1
  end

  defp handle_trace(trace, n) do
    Logger.info("Ignoring unexpected trace: #{inspect(trace)}")
    n
  end

  @spec persist_trace(Trace.t()) :: :ok | {:error, term()}
  defp persist_trace(%Trace{pid: pid, id: id} = trace) do
    TraceService.insert(pid, id, trace)

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
end
