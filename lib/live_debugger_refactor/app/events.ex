defmodule LiveDebuggerRefactor.App.Events do
  @moduledoc """
  Temporary events for the LiveDebuggerRefactor app.
  """

  use LiveDebuggerRefactor.Event

  defevent(SettingsChanged,
    key: :dead_view_mode | :tracing_update_on_code_reload,
    value: term()
  )

  defevent(TracingRefreshed)
end
