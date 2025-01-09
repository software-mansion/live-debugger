defmodule LiveDebugger.Utils.Parsers do
  @moduledoc """
    This module provides functions to parse some structs to string representation and vice versa.
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

  @spec pid_to_string(pid :: pid()) :: String.t()
  def pid_to_string(pid) when is_pid(pid) do
    pid |> :erlang.pid_to_list() |> to_string() |> String.slice(1..-2//1)
  end

  @spec string_to_pid(string :: String.t()) :: pid()
  def string_to_pid(string) when is_binary(string) do
    :erlang.list_to_pid(~c"<#{string}>")
  end
end
