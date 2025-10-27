defmodule LiveDebugger.Services.CallbackTracer.Events do
  @moduledoc """
  Temporary events for LiveDebugger.Services.CallbackTracer.
  """

  use LiveDebugger.Event

  alias LiveDebugger.CommonTypes
  alias LiveDebugger.Structs.Trace.FunctionTrace
  alias LiveDebugger.Structs.DiffTrace

  defevent(TraceCalled,
    trace_id: FunctionTrace.id(),
    ets_ref: reference() | nil,
    module: module(),
    function: atom(),
    arity: non_neg_integer(),
    pid: pid(),
    cid: CommonTypes.cid() | nil,
    transport_pid: pid()
  )

  defevent(TraceReturned,
    trace_id: FunctionTrace.id(),
    ets_ref: reference() | nil,
    module: module(),
    function: atom(),
    arity: non_neg_integer(),
    pid: pid(),
    cid: CommonTypes.cid() | nil,
    transport_pid: pid()
  )

  defevent(TraceErrored,
    trace_id: FunctionTrace.id(),
    ets_ref: reference() | nil,
    module: module(),
    function: atom(),
    arity: non_neg_integer(),
    pid: pid(),
    cid: CommonTypes.cid() | nil,
    transport_pid: pid()
  )

  defevent(DiffTraceCreated,
    trace_id: DiffTrace.id(),
    ets_ref: reference() | nil,
    pid: pid()
  )

  defevent(StateChanged, pid: pid())
end
