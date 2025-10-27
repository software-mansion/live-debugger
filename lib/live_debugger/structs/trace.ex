defmodule LiveDebugger.Structs.Trace do
  @moduledoc """
  This module provides a module to represent a trace.
  """

  alias LiveDebugger.Structs.Trace.FunctionTrace
  alias LiveDebugger.Structs.Trace.DiffTrace

  @type t() :: FunctionTrace.t() | DiffTrace.t()

  defguard is_trace(trace) when is_struct(trace, FunctionTrace) or is_struct(trace, DiffTrace)
end
