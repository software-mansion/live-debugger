defmodule LiveDebuggerRefactor.App.Events do
  @moduledoc """
  Temporary events for the LiveDebuggerRefactor app.
  """

  use LiveDebuggerRefactor.Event

  defevent(SettingsChanged, setting_key: atom(), setting_value: term())
  defevent(TracingRefreshed)
end
