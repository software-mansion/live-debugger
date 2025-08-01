defmodule LiveDebuggerRefactor.App.Utils.Parsers do
  @moduledoc """
  Utilities to parse and convert data types.
  """

  alias LiveDebuggerRefactor.CommonTypes

  @time_units ["µs", "ms", "s"]

  @spec time_units() :: [String.t()]
  def time_units(), do: @time_units

  @doc """
  Parses a unix timestamp in microseconds to a string representation of the timestamp.

  ## Examples

      iex> LiveDebuggerRefactor.App.Utils.Parsers.parse_timestamp(1_000_000)
      "00:00:01.000000"
  """
  @spec parse_timestamp(non_neg_integer()) :: String.t()
  def parse_timestamp(timestamp) when is_integer(timestamp) and timestamp > 0 do
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

  @doc """
  Parses a microseconds to a string representation of the elapsed time.

  ## Examples

      iex> LiveDebuggerRefactor.App.Utils.Parsers.parse_elapsed_time(1_000)
      "1 ms"
  """
  @spec parse_elapsed_time(non_neg_integer() | nil) :: String.t()
  def parse_elapsed_time(nil), do: ""

  def parse_elapsed_time(microseconds) do
    cond do
      microseconds < 1_000 -> "#{microseconds} µs"
      microseconds < 1_000_000 -> "#{div(microseconds, 1_000)} ms"
      true -> "#{:io_lib.format("~.2f", [microseconds / 1_000_000])} s"
    end
  end

  @doc """
  Converts PID to string representation (`"0.123.0"`).
  """
  @spec pid_to_string(pid()) :: String.t()
  def pid_to_string(pid) when is_pid(pid) do
    pid
    |> :erlang.pid_to_list()
    |> to_string()
    |> String.slice(1..-2//1)
  end

  @doc """
  Converts PID string representation (e.g. `"0.123.0"`) to valid PID.

  ## Examples

      iex> LiveDebuggerRefactor.App.Utils.Parsers.string_to_pid("0.123.0")
      {:ok, #PID<0.123.0>}

      iex> LiveDebuggerRefactor.App.Utils.Parsers.string_to_pid("invalid")
      :error
  """
  @spec string_to_pid(string :: String.t()) :: {:ok, pid()} | :error
  def string_to_pid(string) when is_binary(string) do
    if String.match?(string, ~r/[0-9]+\.[0-9]+\.[0-9]+/) do
      {:ok, :erlang.list_to_pid(~c"<#{string}>")}
    else
      :error
    end
  end

  @spec cid_to_string(cid :: CommonTypes.cid()) :: String.t()
  def cid_to_string(%Phoenix.LiveComponent.CID{cid: cid}) do
    Integer.to_string(cid)
  end

  @spec module_to_string(module :: module()) :: String.t()
  def module_to_string(module) do
    module
    |> Module.split()
    |> Enum.join(".")
  end
end
