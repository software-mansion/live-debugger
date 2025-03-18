defmodule LiveDebugger.Utils.URL do
  @moduledoc """
  URL utilities for managing URLs and query params.
  """

  @doc """
  Converts an absolute URL to a relative URL.

  ## Examples

      iex> URL.to_relative("http://example.com/foo?bar=baz")
      "/foo?bar=baz"
  """
  @spec to_relative(utl :: String.t()) :: String.t()
  def to_relative(url) when is_binary(url) do
    %{path: path, query: query} = URI.parse(url)

    URI.to_string(%URI{path: path, query: query})
  end

  @spec update_path(url :: String.t(), path :: String.t()) :: String.t()
  def update_path(url, path) when is_binary(url) and is_binary(path) do
    uri = URI.parse(url)

    URI.to_string(%URI{uri | path: path})
  end

  @spec upsert_query_param(url :: String.t(), key :: String.t(), value :: String.t()) ::
          String.t()
  def upsert_query_param(url, key, value) do
    upsert_query_params(url, %{key => value})
  end

  @spec upsert_query_params(url :: String.t(), params :: %{String.t() => String.t()}) ::
          String.t()
  def upsert_query_params(url, params) do
    modify_query_params(url, &Map.merge(&1, params))
  end

  @spec remove_query_param(url :: String.t(), key :: String.t()) :: String.t()
  def remove_query_param(url, key) do
    modify_query_params(url, &Map.delete(&1, key))
  end

  @spec remove_query_params(url :: String.t(), keys :: [String.t()]) :: String.t()
  def remove_query_params(url, keys) do
    modify_query_params(url, &Map.drop(&1, keys))
  end

  @spec modify_query_params(url :: String.t(), fun :: (map() -> map())) :: String.t()
  def modify_query_params(url, fun) do
    uri = URI.parse(url)

    params =
      (uri.query || "")
      |> URI.decode_query()
      |> fun.()
      |> URI.encode_query()

    URI.to_string(%URI{uri | query: params})
  end
end
