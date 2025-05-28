defmodule LiveDebugger.Utils.Memory do
  @moduledoc """
  Utility functions for measuring memory usage and size of data structures.
  """

  @doc """
  Returns the memory size of an ETS table in bytes.
  """
  @spec table_size(table :: :ets.table()) :: non_neg_integer()
  def table_size(table) do
    case :ets.info(table, :memory) do
      size when is_integer(size) ->
        size * :erlang.system_info(:wordsize)

      _ ->
        0
    end
  end

  @doc """
  Returns the size of an elixir term in bytes.
  """
  @spec term_size(term :: term()) :: non_neg_integer()
  def term_size(term) do
    term |> :erlang.term_to_binary() |> byte_size()
  end
end
