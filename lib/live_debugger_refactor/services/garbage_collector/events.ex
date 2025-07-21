defmodule LiveDebuggerRefactor.Services.GarbageCollector.Events do
  @moduledoc """
  Events for LiveDebuggerRefactor.Services.GarbageCollector.
  """

  use LiveDebuggerRefactor.Event

  defevent(GarbageCollected)
  defevent(TableDeleted)
  defevent(TableTrimmed)
end
