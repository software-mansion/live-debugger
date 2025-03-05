defmodule LiveDebugger.Structs.LvProcess do
  @moduledoc """
  This module provides a struct to represent a LiveView process.

  The struct distinguishes between the root process and the nested processes.
  """

  defstruct [:socket_id, :root_pid, :pid, :transport_pid, :nested?]

  @type t() :: %__MODULE__{
          socket_id: String.t(),
          root_pid: pid(),
          pid: pid(),
          transport_pid: pid(),
          nested?: boolean()
        }

  @spec new(pid :: pid(), socket :: Phoenix.LiveView.Socket.t()) :: t()
  def new(pid, socket) do
    nested? = pid != socket.root_pid

    %__MODULE__{
      socket_id: socket.id,
      root_pid: socket.root_pid,
      pid: pid,
      transport_pid: socket.transport_pid,
      nested?: nested?
    }
  end
end
