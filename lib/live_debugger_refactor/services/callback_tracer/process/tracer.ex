defmodule LiveDebuggerRefactor.Services.CallbackTracer.Process.Tracer do
  @moduledoc """
  This module defines a function that used in the `:dbg.tracer` process.
  """

  @spec handle_trace(args :: term(), n :: integer()) :: integer()
  def handle_trace(args, n) do
    dbg("New rough trace")
    dbg(args)
    n - 1
  end
end
