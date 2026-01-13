defmodule LiveDebugger.Services.CallbackTracer.GenServers.TraceHandler do
  @moduledoc """
  GenServer for handling trace data.
  """

  use GenServer

  require Logger

  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils
  alias LiveDebugger.Services.CallbackTracer.Actions.FunctionTrace, as: TraceActions
  alias LiveDebugger.Services.CallbackTracer.Actions.State, as: StateActions
  alias LiveDebugger.Services.CallbackTracer.Actions.DiffTrace, as: DiffActions
  alias LiveDebugger.Structs.Trace.FunctionTrace

  alias LiveDebugger.API.TracesStorage
  alias LiveDebugger.Structs.Trace.TraceError
  alias LiveDebugger.App.Utils.Parsers

  @allowed_callbacks Enum.map(CallbackUtils.all_callbacks(), &elem(&1, 0))

  @typedoc """
  Trace record is a tuple of:
  - reference to ETS table
  - trace struct
  - timestamp of the trace

  We are storing this tuple in the state of this GenServer to calculate execution time of callbacks.
  """
  @type trace_record :: {reference(), FunctionTrace.t(), non_neg_integer()}

  @typedoc """
  Trace key is a tuple of:
  - pid of the process that called the callback
  - module of the callback
  - function of the callback
  """
  @type trace_key :: {pid(), module(), atom()}
  @type state :: %{trace_key => trace_record}

  @spec start_link(opts :: list()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Handles trace from `:dbg.tracer` process.
  """
  @spec handle_trace(trace :: term(), n :: integer()) :: :ok
  def handle_trace(trace, n) do
    GenServer.cast(__MODULE__, {:new_trace, trace, n})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
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
    Task.start(fn ->
      with {:ok, trace} <- TraceActions.create_delete_component_trace(n, args, pid, cid, ts),
           :ok <- StateActions.maybe_save_state!(trace),
           :ok <- TraceActions.publish_trace(trace) do
        :ok
      else
        :live_debugger_trace ->
          :ok

        {:error, err} ->
          raise "Error while handling trace: #{inspect(err)}"
      end
    end)

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

  def handle_cast({:new_trace, {_, pid, :call, {module, fun, args}, ts}, n}, state)
      when fun in @allowed_callbacks do
    with {:ok, trace} <- TraceActions.create_trace(n, module, fun, args, pid, ts),
         {:ok, ref} <- TraceActions.persist_trace(trace),
         :ok <- TraceActions.publish_trace(trace, ref) do
      {:noreply, put_trace_record(state, trace, ref, ts)}
    else
      {:error, "Transport PID is nil"} ->
        {:noreply, state}

      {:error, err} ->
        raise "Error while handling trace: #{inspect(err)}"
    end
  end

  def handle_cast(
        {:new_trace, {_, pid, type, {module, fun, _}, return_value, return_ts}, _n},
        state
      )
      when fun in @allowed_callbacks and type in [:return_from, :exception_from] do
    with trace_key <- {pid, module, fun},
         {ref, trace, ts} <- get_trace_record(state, trace_key),
         execution_time <- calculate_execution_time(return_ts, ts),
         params <- %{execution_time: execution_time, type: type, return_value: return_value},
         {:ok, updated_trace} <- TraceActions.update_trace(trace, params),
         {:ok, ref} <- TraceActions.persist_trace(updated_trace, ref),
         _ <- StateActions.maybe_save_state!(updated_trace),
         :ok <- TraceActions.publish_trace(updated_trace, ref) do
      {:noreply, delete_trace_record(state, trace_key)}
    else
      :trace_record_not_found ->
        {:noreply, state}

      {:error, err} ->
        raise "Error while handling trace: #{inspect(err)}"
    end
  end

  #########################################################
  # Handling diffs tracing
  #
  # Use :dbg.p(channel_pid, [:s]) to activate
  #########################################################

  def handle_cast({:new_trace, {_, pid, :send, {:socket_push, :text, iodata}, _, ts}, n}, state) do
    with {:ok, diff_trace} <- DiffActions.maybe_create_diff(n, pid, ts, iodata),
         {:ok, ref} <- DiffActions.persist_trace(diff_trace),
         :ok <- DiffActions.publish_diff(diff_trace, ref) do
      {:noreply, state}
    else
      {:error, err} ->
        raise "Error while handling trace: #{inspect(err)}"
    end
  end

  def handle_cast({:new_trace, {_, _pid, :send, _, _, _}, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:new_trace, {_, _, :exit, :normal, _}, _}, state),
    do: {:noreply, state}

  def handle_cast({:new_trace, {_, _, :exit, :shutdown, _}, _}, state),
    do: {:noreply, state}

  def handle_cast({:new_trace, {_, _, :exit, {:shutdown, _}, _}, _}, state),
    do: {:noreply, state}

  def handle_cast(
        {:new_trace, {_, pid, :exit, reason, ts}, _n},
        state
      ) do
    timestamp_str = ts |> format_ts()
    raw_error_banner = "#{timestamp_str} [exit] GenServer #{inspect(pid)} terminating \n"

    {message, stacktrace_str} = normalize_error(reason)

    with table <- TracesStorage.get_table(pid),
         {:ok, {_key, trace}} <- TracesStorage.get_latest_function_trace(table),
         new_trace <- add_error_to_trace(trace, message, stacktrace_str, raw_error_banner),
         {:ok, ref} <- TraceActions.persist_trace(new_trace),
         {:ok} <- TraceActions.publish_trace_exception(new_trace, ref) do
      :ok
    end

    {:noreply, state}
  end

  #########################################################
  # Handling unknown traces
  #########################################################

  def handle_cast({:new_trace, _trace, _n}, state) do
    {:noreply, state}
  end

  defp put_trace_record(state, trace, ref, timestamp) do
    Map.put(state, {trace.pid, trace.module, trace.function}, {ref, trace, timestamp})
  end

  defp get_trace_record(state, trace_key) do
    Map.get(state, trace_key, :trace_record_not_found)
  end

  defp delete_trace_record(state, trace_key) do
    Map.delete(state, trace_key)
  end

  defp calculate_execution_time(return_ts, call_ts) do
    :timer.now_diff(return_ts, call_ts)
  end

  defp format_ts({mega, sec, micro}) do
    unix_micro = (mega * 1_000_000 + sec) * 1_000_000 + micro
    Parsers.parse_timestamp(unix_micro)
  end

  defp add_error_to_trace(trace, message, stacktrace, raw_error_banner) do
    %{
      trace
      | error:
          TraceError.new(
            shorten_message(message),
            stacktrace,
            raw_error_banner <> message <> " \n" <> stacktrace
          ),
        type: :exception_from
    }
  end

  defp normalize_error({reason, stacktrace}) when is_list(stacktrace) do
    {
      Exception.format_banner(:error, reason),
      Exception.format_stacktrace(stacktrace)
    }
  end

  defp normalize_error(reason) do
    {
      "** (stop) " <> inspect(reason),
      "(Stacktrace not available)"
    }
  end

  defp shorten_message(message) do
    message
    |> String.split(~r/\.(\s|$)/, parts: 2)
    |> List.first()
  end
end
