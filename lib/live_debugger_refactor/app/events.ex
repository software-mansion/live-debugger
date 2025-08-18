defmodule LiveDebuggerRefactor.App.Events do
  @moduledoc """
  Events emitted by the LiveDebuggerRefactor UI.
  """

  use LiveDebuggerRefactor.Event

  alias LiveDebuggerRefactor.Structs.LvProcess

  defevent(UserChangedSettings,
    key: :dead_view_mode | :tracing_update_on_code_reload,
    value: term(),
    from: pid()
  )

  defevent(UserRefreshedTrace)

  defevent(DebuggerMounted, debugged_pid: pid(), debugger_pid: pid())
  defevent(DebuggerTerminated, debugger_pid: pid())

  defevent(FindSuccessor, lv_process: LvProcess.t())
end
