defmodule LiveDebugger.Services.TelemetryHandler.Events do
  @moduledoc """
  Events produced by LiveDebugger.Services.TelemetryHandler.
  """

  use LiveDebugger.Event

  alias LiveDebugger.CommonTypes

  defevent(LiveComponentDeleted, pid: pid(), cid: CommonTypes.cid())

  defevent(TelemetryEmitted,
    source: :live_view | :live_component,
    type: :mount | :handle_params | :render | :update,
    stage: :start | :stop,
    pid: pid(),
    cid: CommonTypes.cid() | nil,
    transport_pid: pid()
  )
end
