defmodule LiveDebugger.Structs.LvState do
  @moduledoc """
  This module provides a struct to represent a LiveView state.
  """

  defstruct [:pid, :socket, :components, :assigns_history]

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
          assigns_history: [map()]
        }
end
