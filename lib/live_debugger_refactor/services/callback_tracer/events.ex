defmodule LiveDebuggerRefactor.Services.CallbackTracer.Events do
  @moduledoc """
  Temporary events for LiveDebuggerRefactor.Services.CallbackTracer.
  """

  use LiveDebuggerRefactor.Event

  alias LiveDebugger.CommonTypes
  alias LiveDebuggerRefactor.Structs.Trace

  defevent(TraceCalled,
    trace_id: Trace.id(),
    ets_ref: reference() | nil,
    module: module(),
    function: atom(),
    pid: pid(),
    cid: CommonTypes.cid() | nil
  )

  defevent(TraceReturned,
    trace_id: Trace.id(),
    ets_ref: reference() | nil,
    module: module(),
    function: atom(),
    pid: pid(),
    cid: CommonTypes.cid() | nil
  )

  defevent(TraceErrored,
    trace_id: Trace.id(),
    ets_ref: reference() | nil,
    module: module(),
    function: atom(),
    pid: pid(),
    cid: CommonTypes.cid() | nil
  )
end
