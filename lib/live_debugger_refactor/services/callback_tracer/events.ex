defmodule LiveDebuggerRefactor.Services.CallbackTracer.Events do
  @moduledoc """
  Temporary events for LiveDebuggerRefactor.Services.CallbackTracer.
  """

  use LiveDebuggerRefactor.Event

  alias LiveDebugger.CommonTypes

  defevent(TraceCalled,
    id: neg_integer(),
    module: module(),
    function: atom(),
    cid: CommonTypes.cid() | nil
  )

  defevent(TraceReturned,
    id: neg_integer(),
    module: module(),
    function: atom(),
    cid: CommonTypes.cid() | nil
  )
end
