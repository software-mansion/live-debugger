defmodule LiveDebuggerRefactor.Services.CallbackTracer.Events do
  @moduledoc """
  Temporary events for LiveDebuggerRefactor.Services.CallbackTracer.
  """

  use LiveDebuggerRefactor.Event

  defevent(TraceCalled, id: neg_integer(), module: module(), function: atom())
  defevent(TraceReturned, id: neg_integer(), module: module(), function: atom())
end
