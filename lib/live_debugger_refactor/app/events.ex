defmodule LiveDebuggerRefactor.App.Events do
  @moduledoc """
  Temporary events for the LiveDebuggerRefactor app.
  """

  use LiveDebuggerRefactor.Event

  defevent(UserChangedSettings,
    key: :dead_view_mode | :tracing_update_on_code_reload,
    value: term(),
    from: pid()
  )

  defevent(UserRefreshedTrace)

  defevent(DebuggerMounted, debugged_pid: pid(), debugger_pid: pid())
  defevent(DebuggerTerminated, debugged_pid: pid(), debugger_pid: pid())
  defevent(ParamsChanged, params: map())
end
