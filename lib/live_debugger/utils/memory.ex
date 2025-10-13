defmodule LiveDebugger.Utils.Memory do
  @moduledoc """
  Utility functions for measuring memory usage and size of data structures.
  These functions provide only a good approximation
  """

  @wordsize :erlang.system_info(:wordsize)
  @kilobyte 1024
  @megabyte 1_048_576
  @gigabyte 1_073_741_824

  @doc """
  Returns the size of an elixir term serialized to binary in bytes.
  """
  @spec serialized_term_size(term :: term()) :: non_neg_integer()
  def serialized_term_size(term) do
    term |> :erlang.term_to_binary() |> byte_size()
  end

  @doc """
  Returns the size of an elixir term stored in the process heap in bytes.
  """
  @spec term_heap_size(term :: term()) :: non_neg_integer()
  def term_heap_size(term) do
    :erts_debug.size(term) * @wordsize
  end

  @doc """
  Converts bytes to a human-readable string
  """
  @spec bytes_to_pretty_string(non_neg_integer()) :: String.t()
  def bytes_to_pretty_string(n) when n < @kilobyte, do: "#{n}B"

  def bytes_to_pretty_string(n) when n < @megabyte do
    "#{format_float(n / @kilobyte, 1)}KB"
  end

  def bytes_to_pretty_string(n) when n < @gigabyte do
    "#{format_float(n / @megabyte, 1)}MB"
  end

  def bytes_to_pretty_string(n) do
    "#{format_float(n / @gigabyte, 2)}GB"
  end

  defp format_float(value, decimals) do
    :erlang.float_to_binary(value, decimals: decimals)
  end
end
