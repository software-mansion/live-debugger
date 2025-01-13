defmodule LiveDebugger.Structs.Trace do
  @moduledoc """
  This module provides a struct to represent a trace.
  """

  alias LiveDebugger.Services.TreeNode.LiveComponent

  defstruct [:id, :module, :function, :arity, :args, :pid, :cid, :timestamp]

  @type t() :: %__MODULE__{
          id: integer(),
          module: atom(),
          function: atom(),
          arity: non_neg_integer(),
          args: list(),
          pid: pid(),
          cid: struct() | nil,
          timestamp: non_neg_integer()
        }

  @doc """
  Creates a new trace struct.
  PID is always present, CID is optional - it is filled when trace comes from LiveComponent.
  """
  @spec new(integer(), atom(), atom(), list(), pid()) :: t()
  def new(id, module, function, args, pid) do
    new(id, module, function, args, pid, get_cid_from_args(args))
  end

  @spec new(integer(), atom(), atom(), list(), pid(), LiveComponent.cid()) :: t()
  def new(id, module, function, args, pid, cid) do
    %__MODULE__{
      id: id,
      module: module,
      function: function,
      arity: length(args),
      args: args,
      pid: pid,
      cid: cid,
      timestamp: :os.system_time(:microsecond)
    }
  end

  @doc """
  Returns the node id from the trace.
  It is PID if trace comes from a LiveView, CID if trace comes from a LiveComponent.
  """

  @spec node_id(t()) :: pid() | struct()
  def node_id(%__MODULE__{cid: cid}) when not is_nil(cid), do: cid
  def node_id(%__MODULE__{pid: pid}), do: pid

  defp get_cid_from_args(args) do
    args
    |> Enum.map(&maybe_get_cid(&1))
    |> Enum.find(fn elem -> is_struct(elem, Phoenix.LiveComponent.CID) end)
  end

  defp maybe_get_cid(%{myself: cid}), do: cid
  defp maybe_get_cid(%{assigns: %{myself: cid}}), do: cid
  defp maybe_get_cid(_), do: nil
end
