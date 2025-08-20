defmodule LiveDebugger.Services.SuccessorDiscoverer.Events do
  @moduledoc """
  Events for the `SuccessorDiscoverer` service.
  """

  use LiveDebugger.Event

  alias LiveDebugger.Structs.LvProcess

  defevent(SuccessorFound, old_socket_id: String.t(), new_lv_process: LvProcess.t())
  defevent(SuccessorNotFound, socket_id: String.t())
end
