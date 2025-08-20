defmodule LiveDebugger.Utils.Memory do
  @moduledoc """
  Utility functions for measuring memory usage and size of data structures.
  These functions provide only a good approximation
  """

  @doc """
  Returns the approximate size of an elixir term in bytes.
  """
  @spec term_size(term :: term()) :: non_neg_integer()
  def term_size(term) do
    term |> :erlang.term_to_binary() |> byte_size()
  end
end
