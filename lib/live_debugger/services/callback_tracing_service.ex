defmodule LiveDebugger.Services.CallbackTracingService do
  @moduledoc """
  It starts a tracing session for the given monitored PID via `start_tracing/3`.
  When session is started sends traces to the recipient PID via message {:new_trace, trace}.
  It stores traces in an ETS table with id created by `CallbackTracingService.ets_table_id/1`.

  Traces ids starts from 0 and are decremented by 1 to make sure that they are ordered from the newest to the oldest.
  This is how ets ordered set works. It does not allow you to change the order manually, it is always ordered by the key.

  The session should be stopped when monitored process is killed with `stop_tracing/1`.
  """

  require Logger

  alias LiveDebugger.Services.ModuleDiscoveryService
  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils
  alias LiveDebugger.Structs.Trace
  alias Phoenix.LiveComponent.CID
  alias LiveDebugger.Services.TraceService

  @typedoc """
  Represents a raw trace straight from `:dbg.
  It should not be used outside of this module.
  """
  @type raw_trace :: {atom(), pid(), atom(), {atom(), atom(), [term()]}}

  @dbg_sessions_available Code.ensure_compiled(:dbg) && function_exported?(:dbg, :session, 2)

  @doc """
  Starts a tracing for the given monitored PID.
  It sends traces to the recipient PID via message {:new_trace, trace}.
  It stores traces in an ETS table with id created by `CallbackTracingService.ets_table_id/1`.

  Since session mechanism is available only in OTP >= 27 it is impossible to have multiple tracing sessions in earlier versions.
  Because of that when debugger is used in project with OTP < 27 user cannot open more than one debugger sessions at the same time.
  More info here https://www.erlang.org/docs/27/apps/runtime_tools/dbg#session/2
  """

  @spec start_tracing(
          socket_id :: String.t(),
          monitored_pid :: pid(),
          recipient_pid :: pid()
        ) ::
          {:ok, term()} | {:error, term()}
  def start_tracing(socket_id, monitored_pid, recipient_pid) do
    start_tracing_impl(socket_id, monitored_pid, recipient_pid)
  end

  @doc """
  Stops tracing.
  """
  @spec stop_tracing(term()) :: :ok
  def stop_tracing(session) do
    stop_tracing_impl(session)
  end

  if @dbg_sessions_available do
    defp start_tracing_impl(socket_id, monitored_pid, recipient_pid) do
      with ets_table_id <- TraceService.ets_table_id(socket_id),
           _table <- TraceService.init_ets(ets_table_id),
           next_tuple_id <- TraceService.next_tuple_id(ets_table_id),
           tracing_session_id <- tracing_session_id(monitored_pid),
           tracing_session <- :dbg.session_create(tracing_session_id) do
        :dbg.session(tracing_session, fn ->
          do_trace(ets_table_id, monitored_pid, recipient_pid, next_tuple_id)
        end)

        {:ok, tracing_session}
      end
    rescue
      err ->
        Logger.error("Error while starting tracing: #{inspect(err)}")
        {:error, err}
    end

    defp stop_tracing_impl(session) do
      :dbg.session_destroy(session)
    end

    defp tracing_session_id(monitored_pid) do
      id_prefix = "lvdbg"
      parsed_pid = monitored_pid |> :erlang.pid_to_list() |> to_string()
      String.to_atom("#{id_prefix}-#{parsed_pid}")
    end
  end

  unless @dbg_sessions_available do
    defp start_tracing_impl(socket_id, monitored_pid, recipient_pid) do
      with :ok <- check_session_limit(),
           ets_table_id <- TraceService.ets_table_id(socket_id),
           _table <- TraceService.init_ets(ets_table_id),
           next_tuple_id <- TraceService.next_tuple_id(ets_table_id) do
        do_trace(ets_table_id, monitored_pid, recipient_pid, next_tuple_id)

        {:ok, nil}
      end
    rescue
      err ->
        Logger.error("Error while starting tracing: #{inspect(err)}")
        {:error, err}
    end

    defp stop_tracing_impl(nil) do
      :dbg.stop()
    end

    defp check_session_limit() do
      if LiveDebugger.Services.LiveViewDiscoveryService.debugger_live_pids() == [] do
        :ok
      else
        {:error, :session_limit}
      end
    end
  end

  defp do_trace(ets_table_id, monitored_pid, recipient_pid, next_tuple_id) do
    :dbg.tracer(
      :process,
      {fn msg, n -> trace_handler(msg, n, ets_table_id, recipient_pid) end, next_tuple_id}
    )

    :dbg.p(monitored_pid, :c)

    all_modules = ModuleDiscoveryService.all_modules()

    callbacks =
      all_modules
      |> ModuleDiscoveryService.live_view_modules()
      |> CallbackUtils.live_view_callbacks()

    tracer_patterns =
      all_modules
      |> ModuleDiscoveryService.live_component_modules()
      |> CallbackUtils.live_component_callbacks()
      |> Enum.concat(callbacks)
      |> Enum.map(fn mfa -> :dbg.tp(mfa, []) end)

    [:dbg.tp({Phoenix.LiveView.Diff, :delete_component, 2}, []) | tracer_patterns]
  end

  defp trace_handler(
         {_, pid, _, {Phoenix.LiveView.Diff, :delete_component, [cid_int | _] = args}},
         n,
         ets_table_id,
         recipient_pid
       ) do
    cid = %CID{cid: cid_int}

    n
    |> Trace.new(Phoenix.LiveView.Diff, :delete_component, args, pid, cid)
    |> do_handle(recipient_pid, ets_table_id, n)
  end

  defp trace_handler({_, pid, _, {module, function, args}}, n, ets_table_id, recipient_pid) do
    n
    |> Trace.new(module, function, args, pid)
    |> do_handle(recipient_pid, ets_table_id, n)
  end

  defp do_handle(trace, recipient_pid, ets_table_id, n) do
    try do
      TraceService.insert(ets_table_id, n, trace)
      send(recipient_pid, {:new_trace, trace})
    rescue
      err ->
        Logger.error("Error while handling trace: #{inspect(err)}")
    end

    n - 1
  end
end
