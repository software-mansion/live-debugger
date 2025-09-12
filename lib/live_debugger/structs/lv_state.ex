defmodule LiveDebugger.Structs.LvState do
  @moduledoc """
  This module provides a struct to represent a LiveView state.
  """

  defstruct [:pid, :socket, :components, to_remove: false]

  @type component() :: %{
          id: String.t(),
          cid: integer(),
          module: module(),
          assigns: map(),
          children_cids: [integer()]
        }

  @type t() :: %__MODULE__{
          pid: pid(),
          socket: Phoenix.LiveView.Socket.t(),
          components: [component()],
          to_remove: boolean()
        }
end
