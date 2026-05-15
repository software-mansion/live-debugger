defmodule LiveDebugger.Services.CallbackTracer.Process.Tracer do
  @moduledoc """
  This module defines a function that is used as the handler in the tracer process
  started by `LiveDebugger.API.System.Dbg.tracer/1`.
  """

  alias LiveDebugger.Services.CallbackTracer.GenServers.TraceHandler
  alias LiveDebugger.Utils.Memory

  @max_heap_size Application.compile_env(:live_debugger, :tracer_max_heap_size, 5)

  @spec handle_trace(trace :: term(), state :: integer() | {:init, integer()}) :: integer()
  def handle_trace(trace, {:init, n}) do
    # Set on first invocation so the limit applies to the tracer process itself
    # (which is the one receiving every BEAM trace message).
    Memory.set_max_heap_size(@max_heap_size)

    do_handle_trace(trace, n)
  end

  def handle_trace(trace, n), do: do_handle_trace(trace, n)

  defp do_handle_trace(trace, n) do
    TraceHandler.handle_trace(trace, n)

    n - 1
  end
end
