defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.TraceDisplay do
  @moduledoc """
  Wrapper for trace to display it in the UI.
  """

  alias LiveDebuggerRefactor.Structs.Trace

  defstruct [:id, :trace, :from_tracing?, :counter, render_body?: false]

  @type t() :: %__MODULE__{
          id: integer(),
          trace: Trace.t(),
          from_tracing?: boolean(),
          render_body?: boolean()
        }

  @spec from_trace(Trace.t(), from_tracing? :: boolean()) :: t()
  def from_trace(%Trace{} = trace, from_tracing? \\ false) do
    %__MODULE__{id: trace.id, trace: trace, from_tracing?: from_tracing?}
  end

  @spec render_body(t()) :: t()
  def render_body(%__MODULE__{} = trace) do
    Map.put(trace, :render_body?, true)
  end
end
