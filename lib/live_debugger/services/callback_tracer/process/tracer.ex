defmodule LiveDebugger.Services.CallbackTracer.Process.Tracer do
  @moduledoc """
  This module defines a function that is used in the `:dbg.tracer` process.
  """

  alias LiveDebugger.Services.CallbackTracer.GenServers.TraceHandler

  @spec handle_trace(trace :: term(), n :: integer()) :: integer()
  def handle_trace(trace, n) do
    TraceHandler.handle_trace(trace, n)

    n - 1
  end
end
