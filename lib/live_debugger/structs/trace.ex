defmodule LiveDebugger.Structs.Trace do
  @moduledoc """
  This module provides a struct to represent a trace.
  """

  defstruct [:module, :function, :arity, :args, :pid, :timestamp]

  @type t() :: %__MODULE__{
          module: atom(),
          function: atom(),
          arity: non_neg_integer(),
          args: list(),
          pid: pid(),
          timestamp: non_neg_integer()
        }

  @doc """
  Creates a new trace struct.
  """
  @spec new(atom(), atom(), list(), pid()) :: t()
  def new(module, function, args, pid) do
    %__MODULE__{
      module: module,
      function: function,
      arity: length(args),
      args: args,
      pid: pid,
      timestamp: :os.system_time(:microsecond)
    }
  end
end
