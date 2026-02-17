defmodule LiveDebugger.Services.TelemetryHandler.Events do
  @moduledoc """
  Events produced by LiveDebugger.Services.TelemetryHandler.
  """

  use LiveDebugger.Event

  defevent(StateChanged, pid: pid())

  defevent(TelemetryEmitted,
    source: :live_component,
    type: :destroyed,
    pid: pid(),
    cid: CommonTypes.cid()
  )
end
