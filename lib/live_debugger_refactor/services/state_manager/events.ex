defmodule LiveDebuggerRefactor.Services.StateManager.Events do
  @moduledoc """
  Events produced by the `StateManager` service.
  """

  use LiveDebuggerRefactor.Event

  defevent(StateChanged, pid: pid())
end
