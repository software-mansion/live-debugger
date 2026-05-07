defmodule LiveDebugger.Services.CallbackTracer.Process.Tracer do
  @moduledoc """
  Handler installed in the `:dbg.trace_client` process (`:ip` mode).

  Receives trace tuples decoded by the IP trace port driver and forwards them
  to `TraceHandler` for processing. Drop notifications from queue overflow are
  forwarded too, so the handler can broadcast a user-visible warning.
  """

  alias LiveDebugger.Services.CallbackTracer.GenServers.TraceHandler
  alias LiveDebugger.Utils.Memory

  @max_heap_size Application.compile_env(:live_debugger, :tracer_max_heap_size, 5)

  @spec handle_trace(trace :: term(), state :: integer() | {:init, integer()}) :: integer()
  def handle_trace(trace, {:init, n}) do
    # Heap cap is set on the trace_client process — it owns the decoded trace
    # terms and the cast-mailbox into `TraceHandler`, so it's the right place
    # to enforce a kill-on-runaway boundary.
    Memory.set_max_heap_size(@max_heap_size)

    do_handle_trace(trace, n)
  end

  def handle_trace(trace, n), do: do_handle_trace(trace, n)

  # `{:drop, N}` is emitted by the IP trace port when its bounded queue
  # discards the oldest events under producer pressure. Forward it as a
  # zero-cost notification; do not consume a trace id.
  defp do_handle_trace({:drop, _n_dropped} = event, n) do
    TraceHandler.handle_trace(event, n)
    n
  end

  defp do_handle_trace(trace, n) do
    TraceHandler.handle_trace(trace, n)

    n - 1
  end
end
