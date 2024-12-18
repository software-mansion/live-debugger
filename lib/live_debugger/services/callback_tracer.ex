defmodule LiveDebugger.Services.CallbackTracer do
  use GenServer

  alias LiveDebugger.Services.ModuleDiscovery
  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils

  def start_link(%{monitored_pid: _, socket_id: _} = args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(%{monitored_pid: monitored_pid, socket_id: socket_id}) do
    prepare_tracing(monitored_pid, socket_id)

    {:ok, %{monitored_pid: monitored_pid, traces: []}}
  end

  @impl true
  def terminate(_reason, _state) do
    :dbg.stop()
  end

  defp prepare_tracing(monitored_pid, socket_id) do
    ets_name = String.to_atom("lvdbg-#{socket_id}")
    dbg(ets_name)
    :ets.new(ets_name, [:ordered_set, :public, :named_table])

    s = :dbg.session_create(:cool_session)

    :dbg.session(s, fn ->
      :dbg.tracer(:process, {fn msg, n -> tracer_function(msg, n, ets_name) end, 0}) |> dbg
      :dbg.p(monitored_pid, :c)

      ModuleDiscovery.find_live_modules()
      |> CallbackUtils.tracing_callbacks()
      |> Enum.map(fn mfa -> :dbg.tp(mfa, []) end)
    end)
  end

  defp tracer_function({_, pid, _, {module, function, args}}, n, ets_name) do
    trace = %{
      module: module,
      function: function,
      arity: length(args),
      args: args,
      pid: pid,
      timestamp: :os.system_time(:microsecond)
    }

    :ets.insert(ets_name, {n, trace})

    n + 1
  end
end
