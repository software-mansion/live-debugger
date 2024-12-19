defmodule LiveDebugger.Services.CallbackTracer do
  alias LiveDebugger.Services.ModuleDiscovery
  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils

  @id_prefix "lvdbg"

  require Logger

  def start_tracing_session(socket_id, monitored_pid, recipient_pid) do
    ets_table_id = ets_table_id(socket_id)
    maybe_init_ets(ets_table_id)
    init_id = ets_init_id(ets_table_id)

    tracing_session =
      monitored_pid
      |> tracing_session_id()
      |> :dbg.session_create()

    :dbg.session(tracing_session, fn ->
      :dbg.tracer(
        :process,
        {fn msg, n -> trace_handler(msg, n, ets_table_id, recipient_pid) end, init_id}
      )

      :dbg.p(monitored_pid, :c)

      ModuleDiscovery.find_live_modules()
      |> CallbackUtils.tracing_callbacks()
      |> Enum.map(fn mfa -> :dbg.tp(mfa, []) end)
    end)

    {:ok, tracing_session}
  end

  def stop_tracing_session(session) do
    :dbg.session_destroy(session)
  end

  def ets_table_id(socket_id), do: String.to_atom("#{@id_prefix}-#{socket_id}")

  defp maybe_init_ets(ets_table_id) do
    if :ets.whereis(ets_table_id) == :undefined do
      Logger.debug("Creating a new ETS table with id: #{ets_table_id}")
      :ets.new(ets_table_id, [:ordered_set, :public, :named_table])
    end
  end

  defp ets_init_id(ets_table_id) do
    case :ets.last(ets_table_id) do
      :"$end_of_table" -> 0
      last_id -> last_id + 1
    end
  end

  defp tracing_session_id(monitored_pid) do
    parsed_pid = monitored_pid |> :erlang.pid_to_list() |> to_string()
    String.to_atom("#{@id_prefix}-#{parsed_pid}")
  end

  defp trace_handler({_, pid, _, {module, function, args}}, n, ets_table_id, recipient_pid) do
    trace = %{
      module: module,
      function: function,
      arity: length(args),
      args: args,
      pid: pid,
      timestamp: :os.system_time(:microsecond)
    }

    :ets.insert(ets_table_id, {n, trace})
    send(recipient_pid, {:new_trace, trace})

    n + 1
  end
end
