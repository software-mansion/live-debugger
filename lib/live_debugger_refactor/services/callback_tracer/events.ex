defmodule LiveDebuggerRefactor.Services.CallbackTracer.Events do
  @moduledoc """
  Temporary events for LiveDebuggerRefactor.Services.CallbackTracer.
  """

  use LiveDebuggerRefactor.Event

  alias LiveDebugger.CommonTypes

  defevent(TraceCalled,
    trace_id: neg_integer() | 0,
    module: module(),
    function: atom(),
    pid: pid(),
    cid: CommonTypes.cid() | nil
  )

  defevent(TraceReturned,
    trace_id: neg_integer() | 0,
    module: module(),
    function: atom(),
    pid: pid(),
    cid: CommonTypes.cid() | nil
  )
end
