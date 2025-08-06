defmodule LiveDebuggerRefactor.Services.SuccessorDiscoverer.Events do
  @moduledoc """
  Events for the `SuccessorDiscoverer` service.
  """

  use LiveDebuggerRefactor.Event

  defevent(SuccessorFound, old_socket_id: String.t(), new_socket_id: String.t())
  defevent(SuccessorNotFound, socket_id: String.t())
end
