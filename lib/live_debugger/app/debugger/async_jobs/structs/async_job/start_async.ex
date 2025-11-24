defmodule LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.StartAsync do
  @moduledoc """
  This module provides a struct to represent a start_async background task.
  """

  defstruct [:pid, :name, :ref]

  @type t() :: %__MODULE__{
          pid: pid(),
          name: atom(),
          ref: reference()
        }

  @spec new(pid(), atom(), reference()) :: t()
  def new(pid, name, ref) do
    %__MODULE__{
      pid: pid,
      name: name,
      ref: ref
    }
  end
end
