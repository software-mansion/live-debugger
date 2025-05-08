defmodule LiveDebugger.Structs.TraceDisplay do
  @moduledoc """
  This module provides a struct used for displaying traces.
  It wraps a trace struct and adds additional information.
  """

  alias LiveDebugger.Structs.Trace

  defstruct [:id, :trace, :render_body?, :from_tracing?, :counter]

  @type t() :: %__MODULE__{
          id: integer(),
          trace: Trace.t(),
          render_body?: boolean(),
          from_tracing?: boolean()
        }

  def from_trace(%Trace{} = trace, from_tracing? \\ false) do
    %__MODULE__{id: trace.id, trace: trace, render_body?: false, from_tracing?: from_tracing?}
  end

  def render_body(%__MODULE__{} = trace) do
    Map.put(trace, :render_body?, true)
  end
end
