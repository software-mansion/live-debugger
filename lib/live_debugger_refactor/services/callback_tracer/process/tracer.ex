defmodule LiveDebuggerRefactor.Services.CallbackTracer.Process.Tracer do
  @moduledoc """
  This module defines a function that used in the `:dbg.tracer` process.
  """

  @spec handle_trace(args :: term(), n :: integer()) :: integer()
  def handle_trace(_args, n) do
    # TODO: Implement tracing logic
    n - 1
  end
end
