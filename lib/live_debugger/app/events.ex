defmodule LiveDebugger.App.Events do
  @moduledoc """
  Events emitted by the LiveDebugger UI.
  """

  use LiveDebugger.Event

  alias LiveDebugger.Structs.LvProcess

  defevent(UserChangedSettings,
    key: :dead_view_mode | :garbage_collection,
    value: term(),
    from: pid()
  )

  defevent(UserRefreshedTrace)

  defevent(DebuggerMounted, debugged_pid: pid(), debugger_pid: pid())

  defevent(FindSuccessor, lv_process: LvProcess.t())
end
