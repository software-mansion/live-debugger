defmodule LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplay do
  @moduledoc """
  Wrapper for trace to display it in the UI.

  * `trace` - trace to display
  * `from_event?` - whether the trace comes from an event
  * `render_body?` - whether to render the body of the trace
  """

  alias LiveDebugger.Structs.Trace

  defstruct [:id, :trace, :from_event?, :counter, render_body?: false]

  @type t() :: %__MODULE__{
          id: Trace.id(),
          trace: Trace.t(),
          from_event?: boolean(),
          render_body?: boolean()
        }

  @spec from_trace(Trace.t(), from_event? :: boolean()) :: t()
  def from_trace(%Trace{} = trace, from_event? \\ false) do
    %__MODULE__{id: trace.id, trace: trace, from_event?: from_event?}
  end

  @spec render_body(t()) :: t()
  def render_body(%__MODULE__{} = trace) do
    Map.put(trace, :render_body?, true)
  end
end
