defmodule LiveDebugger.App.Utils.URL do
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

  @spec update_path(url :: String.t(), path :: String.t()) :: String.t()
  def update_path(url, path) when is_binary(url) and is_binary(path) do
    uri = URI.parse(url)

    URI.to_string(%URI{uri | path: path})
  end

  @spec upsert_query_param(url :: String.t(), key :: String.t(), value :: String.t()) ::
          String.t()
  def upsert_query_param(url, key, value)
      when is_binary(url) and is_binary(key) and is_binary(value) do
    upsert_query_params(url, %{key => value})
  end

  @spec upsert_query_params(url :: String.t(), params :: %{String.t() => String.t()}) ::
          String.t()
  def upsert_query_params(url, params) when is_binary(url) and is_map(params) do
    modify_query_params(url, &Map.merge(&1, params))
  end

  @spec remove_query_param(url :: String.t(), key :: String.t()) :: String.t()
  def remove_query_param(url, key) when is_binary(url) and is_binary(key) do
    modify_query_params(url, &Map.delete(&1, key))
  end

  @spec remove_query_params(url :: String.t(), keys :: [String.t()]) :: String.t()
  def remove_query_params(url, keys) when is_binary(url) and is_list(keys) do
    modify_query_params(url, &Map.drop(&1, keys))
  end

  @spec remove_query_params(url :: String.t()) :: String.t()
  def remove_query_params(url) when is_binary(url) do
    modify_query_params(url, fn _ -> %{} end)
  end

  @spec take_nth_segment(url :: String.t(), n :: integer()) :: String.t() | nil
  def take_nth_segment(url, n) when is_binary(url) and is_integer(n) do
    url
    |> to_relative()
    |> remove_query_params()
    |> String.split("/")
    |> Enum.at(n)
  end

  @spec modify_query_params(url :: String.t(), fun :: (map() -> map())) :: String.t()
  def modify_query_params(url, fun) when is_binary(url) and is_function(fun) do
    uri = URI.parse(url)

    params =
      (uri.query || "")
      |> URI.decode_query()
      |> fun.()
      |> case do
        params when map_size(params) == 0 -> nil
        params -> URI.encode_query(params)
      end

    URI.to_string(%URI{uri | query: params})
  end
end
