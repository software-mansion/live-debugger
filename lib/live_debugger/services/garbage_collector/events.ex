defmodule LiveDebugger.Services.GarbageCollector.Events do
  @moduledoc """
  Events for LiveDebugger.Services.GarbageCollector.
  """

  use LiveDebugger.Event

  defevent(GarbageCollected)
  defevent(TableDeleted)
  defevent(TableTrimmed)
end
