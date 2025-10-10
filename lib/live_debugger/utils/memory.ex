defmodule LiveDebugger.Utils.Memory do
  @moduledoc """
  Utility functions for measuring memory usage and size of data structures.
  These functions provide only a good approximation
  """

  @wordsize :erlang.system_info(:wordsize)

  @doc """
  Returns the approximate size of an elixir term in bytes.
  """
  @spec approx_term_size(term :: term()) :: non_neg_integer()
  def approx_term_size(term) do
    term |> :erlang.term_to_binary() |> byte_size()
  end

  @doc """
  Measures term size inside process heap.
  Ignores large binaries/strings (> 64 bytes).
  """
  @spec term_heap_size(term :: term()) :: non_neg_integer()
  def term_heap_size(term) do
    :erts_debug.size(term) * @wordsize
  end

  @doc """
  Measures the total memory that would be needed if the assigns were deep-copied.
  Includes large off-heap binaries.
  """
  @spec term_total_size(term :: term()) :: non_neg_integer()
  def term_total_size(term) do
    :erts_debug.flat_size(term) * @wordsize
  end
end
