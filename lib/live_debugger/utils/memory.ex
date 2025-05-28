defmodule LiveDebugger.Utils.Memory do
  @moduledoc """
  Utility functions for measuring memory usage and size of data structures.
  """

  @sizes %{
    MB: 1_048_576,
    KB: 1_024,
    B: 1
  }

  @type unit() :: :MB | :KB | :B

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

  @doc """
  Converts a size in unit to bytes.
  """
  @spec bytes(size :: non_neg_integer(), unit :: unit()) ::
          {:ok, number()} | {:error, :invalid_unit}
  def bytes(size, unit) when is_number(size) do
    case Map.get(@sizes, unit) do
      nil -> {:error, :invalid_unit}
      multiplier -> {:ok, size * multiplier}
    end
  end
end
