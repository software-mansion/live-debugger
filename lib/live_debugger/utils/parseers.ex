defmodule LiveDebugger.Utils.Parseers do
  @moduledoc """
  This module provides functions to parse some structs to string representation and vice versa.
  """

  @spec pid_to_string(pid :: pid()) :: String.t()
  def pid_to_string(pid) when is_pid(pid) do
    pid |> :erlang.pid_to_list() |> to_string() |> String.slice(1..-2//1)
  end

  @spec string_to_pid(string :: String.t()) :: pid()
  def string_to_pid(string) when is_binary(string) do
    :erlang.list_to_pid(~c"<#{string}>")
  end
end
