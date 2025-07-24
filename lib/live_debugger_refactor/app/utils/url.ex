defmodule LiveDebuggerRefactor.App.Utils.URL do
  @moduledoc """
  URL utilities for managing URLs and query params.
  """

  @doc """
  Converts an absolute URL to a relative URL.

  ## Examples

      iex> URL.to_relative("http://example.com/foo?bar=baz")
      "/foo?bar=baz"
  """
  @spec to_relative(url :: String.t()) :: String.t()
  def to_relative(url) when is_binary(url) do
    %{path: path, query: query} = URI.parse(url)

    URI.to_string(%URI{path: path, query: query})
  end
end
