defmodule LiveDebugger.Services.CallbackTracer.Process.Tracer do
  @moduledoc """
  This module defines a function that is used in the `:dbg.tracer` process.
  """

  alias LiveDebugger.Services.CallbackTracer.GenServers.TraceHandler
  alias LiveDebugger.Utils.Memory

  @max_heap_size 5

  @spec handle_trace(trace :: term(), n :: integer()) :: integer()
  def handle_trace(trace, {:init, n}) do
    # Maximum heap size is set inside `:dbg.tracer` process to prevent it from consuming too much memory.
    Memory.set_max_heap_size(@max_heap_size)

    do_handle_trace(trace, n)
  end

  def handle_trace(trace, n), do: do_handle_trace(trace, n)

  defp do_handle_trace(trace, n) do
    TraceHandler.handle_trace(trace, n)

    n - 1
  end
end
