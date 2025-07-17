defmodule LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TraceHandler do
  @moduledoc """
  GenServer for handling trace data.
  """

  use GenServer

  require Logger

  alias LiveDebuggerRefactor.Utils.Callbacks, as: CallbackUtils
  alias LiveDebuggerRefactor.Services.CallbackTracer.Actions.Trace, as: TraceActions

  @allowed_callbacks Enum.map(CallbackUtils.all_callbacks(), &elem(&1, 0))

  @type trace_record :: {reference(), Trace.t(), non_neg_integer()}
  @type trace_key :: {pid(), module(), atom()}
  @type state :: %{trace_key => trace_record}

  @spec start_link(opts :: list()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  It sends a raw trace from `:dbg.tracer` process to the GenServer.
  """
  @spec send_trace(trace :: term(), n :: integer()) :: :ok
  def send_trace(trace, n) do
    GenServer.cast(__MODULE__, {:new_trace, trace, n})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  #########################################################
  # Handling recompile events
  #
  # We catch this trace to know when modules were recompiled.
  # We do not display this trace to user, so we do not have to care about order
  # We need to catch that case because tracer disconnects from modules that were recompiled
  # and we need to reapply tracing patterns to them.
  # This will be replaced in the future with a more efficient way to handle this.
  # https://github.com/software-mansion/live-debugger/issues/592
  #
  #########################################################

  @impl true
  def handle_cast(
        {:new_trace, {_, _, :return_from, {Mix.Tasks.Compile.Elixir, _, _}, {:ok, _}, _}, n},
        state
      ) do
    # TODO: Update traced modules
    dbg("Update traced modules")
    dbg([n, state])

    {:noreply, state}
  end

  @impl true
  def handle_cast({:new_trace, {_, _, _, {Mix.Tasks.Compile.Elixir, _, _}, _}, _}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:new_trace, {_, _, _, {Mix.Tasks.Compile.Elixir, _, _}, _, _}, _}, state) do
    {:noreply, state}
  end

  #########################################################
  # Handling component deletion traces
  #
  # We catch this trace to know when components are deleted.
  # We do not display this trace to user, so we do not have to care about order
  # This will be replaced in the future with telemetry event added in LiveView 1.1.0
  # https://hexdocs.pm/phoenix_live_view/1.1.0-rc.3/telemetry.html
  #
  #########################################################

  @impl true
  def handle_cast(
        {:new_trace,
         {_, pid, _, {Phoenix.LiveView.Diff, :delete_component, [cid | _] = args}, ts}, n},
        state
      ) do
    dbg("Delete component")
    dbg([pid, cid, args, ts, n, state])

    {:noreply, state}
  end

  #########################################################
  # Handling standard callback traces
  #
  # To measure execution time of callbacks we save in GenServer timestamp when callback is called.
  # Since LiveView is a single process all callbacks are called in order.
  # This means that we can measure execution time of callbacks by subtracting timestamp when
  # callback is called from timestamp when callback returns.
  #
  #########################################################

  @impl true
  def handle_cast({:new_trace, {_, pid, :call, {module, fun, args}, ts}, n}, state)
      when fun in @allowed_callbacks do
    with {:ok, trace} <- TraceActions.create_trace(n, module, fun, args, pid, ts),
         {:ok, ref} <- TraceActions.persist_trace(trace),
         :ok <- TraceActions.publish_trace(trace, ref) do
      {:noreply, put_trace_record(state, trace, ref, ts)}
    else
      {:error, err} ->
        Logger.error("Error while handling trace: #{inspect(err)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:new_trace, {_, pid, type, {module, fun, _}, _, return_ts}, n}, state)
      when fun in @allowed_callbacks and type in [:return_from, :exception_from] do
    with trace_key <- {pid, module, fun},
         {ref, trace, ts} <- get_trace_record(state, trace_key),
         exec_time <- calculate_execution_time(return_ts, ts),
         {:ok, updated_trace} <- TraceActions.update_trace(trace, %{execution_time: exec_time}),
         {:ok, ref} <- TraceActions.persist_trace(updated_trace, ref),
         :ok <- TraceActions.publish_trace(updated_trace, ref) do
      {:noreply, delete_trace_record(state, trace_key)}
    else
      {:error, err} ->
        Logger.error("Error while handling trace: #{inspect(err)}")
        {:noreply, state}
    end
  end

  #########################################################
  # Handling unknown traces
  #########################################################

  @impl true
  def handle_cast({:new_trace, trace, _n}, state) do
    Logger.info("Ignoring unexpected trace: #{inspect(trace)}")

    {:noreply, state}
  end

  defp put_trace_record(state, trace, ref, timestamp) do
    Map.put(state, {trace.pid, trace.module, trace.function}, {ref, trace, timestamp})
  end

  defp get_trace_record(state, trace_key) do
    Map.get(state, trace_key)
  end

  defp delete_trace_record(state, trace_key) do
    Map.delete(state, trace_key)
  end

  defp calculate_execution_time(return_ts, call_ts) do
    :timer.now_diff(return_ts, call_ts)
  end
end
