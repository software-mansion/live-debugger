defmodule LiveDebugger.Services.CallbackTracer do
  use GenServer

  alias LiveDebugger.Services.ModuleDiscovery
  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils

  def start_link(%{monitored_pid: _, debugger_pid: _} = args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(%{monitored_pid: monitored_pid, debugger_pid: debugger_pid}) do
    prepare_tracing(monitored_pid)

    {:ok, %{monitored_pid: monitored_pid, debugger_pid: debugger_pid, traces: []}}
  end

  @impl true
  def handle_cast({:new_trace, trace}, state) do
    updated_state = Map.put(state, :traces, [trace | state.traces])
    {:noreply, updated_state}
  end

  @impl true
  def terminate(_reason, _state) do
    :dbg.stop()
  end

  defp prepare_tracing(monitored_pid) do
    recipient_pid = self()

    s = :dbg.session_create(:cool_session)

    :dbg.session(s, fn ->
      :dbg.tracer(:process, {fn msg, n -> tracer_function(msg, n, recipient_pid) end, 0}) |> dbg
      :dbg.p(monitored_pid, :c)

      ModuleDiscovery.find_live_modules()
      |> CallbackUtils.tracing_callbacks()
      |> Enum.map(fn mfa -> :dbg.tp(mfa, []) end)
    end)
  end

  defp tracer_function(message, n, recipient_pid) do
    GenServer.cast(recipient_pid, {:new_trace, message})
    n + 1
  end
end
