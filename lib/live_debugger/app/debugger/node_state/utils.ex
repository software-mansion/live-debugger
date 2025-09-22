defmodule LiveDebugger.App.Debugger.NodeState.Utils do
  @moduledoc """
  Utility functions for the Node State.
  """

  @doc """
  Computes a recursive diff between two maps.
  Returns a map of keys that changed, where
  leaf values are `true`.
  """
  @spec diff(map(), map()) :: map()
  def diff(map1, map2) when is_map(map1) and is_map(map2) do
    (Map.keys(map1) ++ Map.keys(map2))
    |> Enum.uniq()
    |> Enum.reduce(%{}, fn key, acc ->
      result1 = Map.fetch(map1, key)
      result2 = Map.fetch(map2, key)

      case compare(result1, result2) do
        nil -> acc
        diff_value -> Map.put(acc, key, diff_value)
      end
    end)
  end

  defp compare(:error, :error), do: nil
  defp compare(:error, {:ok, _}), do: true
  defp compare({:ok, _}, :error), do: true
  defp compare({:ok, v1}, {:ok, v2}), do: compare_values(v1, v2)

  defp compare_values(v1, v2) do
    cond do
      v1 == v2 -> nil
      is_map(v1) and is_map(v2) -> diff(v1, v2)
      true -> true
    end
  end
end
