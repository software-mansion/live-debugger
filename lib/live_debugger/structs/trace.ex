defmodule LiveDebugger.Structs.Trace do
  @moduledoc """
  This module provides a struct to represent a trace.
  """

  defstruct [:module, :function, :arity, :args, :pid, :cid, :timestamp]

  @type t() :: %__MODULE__{
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
  @spec new(atom(), atom(), list(), pid()) :: t()
  def new(module, function, args, pid) do
    %__MODULE__{
      module: module,
      function: function,
      arity: length(args),
      args: args,
      pid: pid,
      cid: get_cid_from_args(args),
      timestamp: :os.system_time(:microsecond)
    }
  end

  defp get_cid_from_args(args) do
    args
    |> Enum.map(&maybe_get_cid(&1))
    |> Enum.find(fn elem -> is_struct(elem, Phoenix.LiveComponent.CID) end)
  end

  defp maybe_get_cid(%{myself: cid}), do: cid
  defp maybe_get_cid(%{assigns: %{myself: cid}}), do: cid
  defp maybe_get_cid(_), do: nil
end
