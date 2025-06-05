defmodule LiveDebugger.Helpers.KeywordHelper do
  @moduledoc """
  This module contains helper functions for working with keyword lists.
  """

  @doc """
  Appends a value to a keyword list if the value is not nil.
  """
  @spec append_if_not_nil(Keyword.t(), atom(), any()) :: Keyword.t()
  def append_if_not_nil(list, _key, value) when is_nil(value), do: list

  def append_if_not_nil(list, key, value) do
    Keyword.put(list, key, value)
  end
end
