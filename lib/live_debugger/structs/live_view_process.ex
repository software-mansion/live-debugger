defmodule LiveDebugger.Structs.LiveViewProcess do
  @moduledoc """
  This module provides a struct to represent a process in the debugged application.

  PID is always present.
  ROOT? is a boolean that indicates if the process is the root process. If not it means that it is a nested LiveView.
  """

  defstruct [:pid, :module, :root?, :root_pid, :parent_pid, :socket_id]

  @type t() :: %__MODULE__{
          pid: pid(),
          module: atom(),
          root?: boolean(),
          root_pid: pid(),
          parent_pid: pid() | nil,
          socket_id: String.t()
        }

  @doc """
  Creates a new process struct.
  """
  @spec new(pid :: pid(), socket :: map()) :: t() | nil
  def new(pid, %Phoenix.LiveView.Socket{} = socket) when is_pid(pid) do
    new(pid, socket.view, socket.root_pid, socket.parent_pid, socket.id)
  end

  def new(_, _), do: nil

  @spec new(pid(), atom(), pid(), pid() | nil, String.t()) :: t()
  def new(pid, module, root_pid, parent_pid, socket_id) do
    %__MODULE__{
      pid: pid,
      module: module,
      root?: root_pid == pid,
      root_pid: root_pid,
      parent_pid: parent_pid,
      socket_id: socket_id
    }
  end
end
