defmodule LiveDebuggerRefactor.App.Utils.Parsers do
  @moduledoc """
  Utility functions to parse and convert data types to string representations and vice versa.
  """

  @doc """
  Converts PID to string representation (`0.123.0`).
  """
  @spec pid_to_string(pid()) :: String.t()
  def pid_to_string(pid) when is_pid(pid) do
    pid
    |> :erlang.pid_to_list()
    |> to_string()
    |> String.slice(1..-2//1)
  end
end
