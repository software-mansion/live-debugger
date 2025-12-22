defmodule LiveDebugger.Structs.Trace.TraceError do
  @moduledoc """
   This module defines a struct for representing trace errors.
  """
  defstruct [
    :message,
    :raw_error,
    :stacktrace
  ]

  @type t :: %__MODULE__{
          message: String.t(),
          raw_error: String.t() | nil,
          stacktrace: String.t() | nil
        }

  @doc """
  Creates a new trace error struct.
  """
  @spec new(String.t(), String.t(), String.t()) :: t()
  def new(error_message, stacktrace, raw_error) do
    %__MODULE__{
      message: error_message,
      stacktrace: stacktrace,
      raw_error: raw_error
    }
  end
end
