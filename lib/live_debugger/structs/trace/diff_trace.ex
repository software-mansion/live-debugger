defmodule LiveDebugger.Structs.Trace.DiffTrace do
  @moduledoc """
  This module provides a struct to represent a LiveView diff that is sent to the client.

  * `id` - unique id of the diff
  * `body` - body of the diff
  * `pid` - pid of the LiveView
  * `timestamp` - timestamp of the diff
  * `size` - size of the diff in bytes
  """

  defstruct [
    :id,
    :pid,
    :timestamp,
    :body,
    :size
  ]

  @type id() :: neg_integer() | 0

  @type t() :: %__MODULE__{
          id: id(),
          body: map(),
          pid: pid(),
          timestamp: non_neg_integer(),
          size: non_neg_integer()
        }

  @doc """
  Creates a new LiveView diff struct.
  """
  @spec new(id(), map(), pid(), :erlang.timestamp(), non_neg_integer()) :: t()
  def new(id, body, pid, timestamp, size) do
    %__MODULE__{
      id: id,
      body: body,
      pid: pid,
      timestamp: :timer.now_diff(timestamp, {0, 0, 0}),
      size: size
    }
  end
end
