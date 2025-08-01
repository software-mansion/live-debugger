defmodule LiveDebuggerRefactor.Structs.LvProcess do
  @moduledoc """
  This module provides a struct to represent a LiveView process.
  It uses `LiveDebuggerRefactor.API.LiveViewDebug` to fetch LiveView process state

  * nested? - whether the process is a nested LiveView process
  * debugger? - whether the process is a LiveDebugger process
  """

  alias LiveDebuggerRefactor.Utils.Modules, as: UtilsModules

  defstruct [
    :socket_id,
    :root_pid,
    :parent_pid,
    :pid,
    :transport_pid,
    :module,
    :nested?,
    :debugger?,
    :embedded?,
    alive?: true
  ]

  @type t() :: %__MODULE__{
          socket_id: String.t(),
          root_pid: pid(),
          parent_pid: pid() | nil,
          pid: pid(),
          transport_pid: pid(),
          module: module(),
          nested?: boolean(),
          embedded?: boolean(),
          debugger?: boolean(),
          alive?: boolean()
        }

  @spec new(pid :: pid(), socket :: Phoenix.LiveView.Socket.t()) :: t()
  def new(pid, socket) do
    nested? = pid != socket.root_pid

    debugger? = UtilsModules.debugger_module?(socket.view)

    embedded? = socket.host_uri == :not_mounted_at_router

    %__MODULE__{
      socket_id: socket.id,
      root_pid: socket.root_pid,
      pid: pid,
      parent_pid: socket.parent_pid,
      transport_pid: socket.transport_pid,
      module: socket.view,
      nested?: nested?,
      debugger?: debugger?,
      embedded?: embedded?
    }
  end

  @doc """
  Creates new LvProcess struct with the given `pid` by fetching the socket from `LiveViewDebug`.
  """
  @spec new(pid :: pid()) :: t() | nil
  def new(pid) do
    case LiveDebuggerRefactor.API.LiveViewDebug.socket(pid) do
      {:ok, socket} ->
        new(pid, socket)

      {:error, _} ->
        nil
    end
  end

  @doc """
  Returns the parent LvProcess of the given `lv_process`.
  """
  @spec parent(lv_process :: t()) :: t() | nil
  def parent(%__MODULE__{parent_pid: nil}), do: nil
  def parent(%__MODULE__{parent_pid: parent_pid}), do: new(parent_pid)
end
