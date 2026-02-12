defmodule LiveDebugger.Services.TelemetryHandler.Events do
  @moduledoc """
  Events produced by LiveDebugger.Services.TelemetryHandler.
  """

  use LiveDebugger.Event

  defevent(LiveComponentDeleted, pid: pid(), cid: CommonTypes.cid())
end
