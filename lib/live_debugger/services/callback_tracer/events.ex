defmodule LiveDebugger.Services.CallbackTracer.Events do
  @moduledoc """
  Temporary events for LiveDebugger.Services.CallbackTracer.
  """

  use LiveDebugger.Event

  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Structs.Trace

  defevent(TraceCalled,
    trace_id: Trace.id(),
    ets_ref: reference() | nil,
    module: module(),
    function: atom(),
    arity: non_neg_integer(),
    pid: pid(),
    cid: CommonTypes.cid() | nil,
    transport_pid: pid()
  )

  defevent(TraceReturned,
    trace_id: Trace.id(),
    ets_ref: reference() | nil,
    module: module(),
    function: atom(),
    arity: non_neg_integer(),
    pid: pid(),
    cid: CommonTypes.cid() | nil,
    transport_pid: pid()
  )

  defevent(TraceErrored,
    trace_id: Trace.id(),
    ets_ref: reference() | nil,
    module: module(),
    function: atom(),
    arity: non_neg_integer(),
    pid: pid(),
    cid: CommonTypes.cid() | nil,
    transport_pid: pid()
  )

  defevent(StateChanged, pid: pid())
end
