defmodule LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.AsyncAssign do
  @moduledoc """
  This module provides a struct to represent an async assign background task.
  """

  defstruct [:pid, :keys, :ref]

  @type t() :: %__MODULE__{
          pid: pid(),
          keys: [atom()],
          ref: reference()
        }

  @spec new(pid(), [atom()], reference()) :: t()
  def new(pid, keys, ref) do
    %__MODULE__{
      pid: pid,
      keys: keys,
      ref: ref
    }
  end
end
