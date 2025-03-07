defmodule LiveDebugger.Structs.TraceDisplay do
  @moduledoc """
  This module provides a struct used for displaying traces.
  It wraps a trace struct and adds additional information.
  """

  alias LiveDebugger.Structs.Trace

  defstruct [:id, :trace, :render_body?, :counter]

  @type t() :: %__MODULE__{
          id: integer(),
          trace: Trace.t(),
          render_body?: boolean()
        }

  def from_historical_trace(%Trace{} = trace) do
    %__MODULE__{id: trace.id, trace: trace, render_body?: true}
  end

  def from_live_trace(%Trace{} = trace) do
    %__MODULE__{id: trace.id, trace: trace, render_body?: false}
  end

  def render_body(%__MODULE__{} = trace) do
    Map.put(trace, :render_body?, true)
  end
end
