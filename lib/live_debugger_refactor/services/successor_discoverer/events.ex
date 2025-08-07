defmodule LiveDebuggerRefactor.Services.SuccessorDiscoverer.Events do
  @moduledoc """
  Events for the `SuccessorDiscoverer` service.
  """

  use LiveDebuggerRefactor.Event

  alias LiveDebuggerRefactor.Structs.LvProcess

  defevent(SuccessorFound, old_socket_id: String.t(), new_lv_process: LvProcess.t())
  defevent(SuccessorNotFound, socket_id: String.t())
end
