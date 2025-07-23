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

  @spec string_to_pid(string :: String.t()) :: {:ok, pid()} | :error
  def string_to_pid(string) when is_binary(string) do
    if String.match?(string, ~r/[0-9]+\.[0-9]+\.[0-9]+/) do
      {:ok, :erlang.list_to_pid(~c"<#{string}>")}
    else
      :error
    end
  end

  @spec cid_to_string(cid :: struct()) :: String.t()
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
