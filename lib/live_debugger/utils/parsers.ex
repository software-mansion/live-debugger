defmodule LiveDebugger.Utils.Parsers do
  @moduledoc """
    Parsers that transfers different data types to formats that are easier to read.
  """

  @spec parse_timestamp(non_neg_integer()) :: String.t()
  def parse_timestamp(timestamp) do
    timestamp
    |> DateTime.from_unix(:microsecond)
    |> case do
      {:ok, %DateTime{hour: hour, minute: minute, second: second, microsecond: {micro, _}}} ->
        "~2..0B:~2..0B:~2..0B.~6..0B"
        |> :io_lib.format([hour, minute, second, micro])
        |> IO.iodata_to_binary()

      _ ->
        "Invalid timestamp"
    end
  end
end
