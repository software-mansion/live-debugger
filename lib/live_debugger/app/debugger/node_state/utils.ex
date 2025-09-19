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
    all_keys = (Map.keys(map1) ++ Map.keys(map2)) |> Enum.uniq()

    all_keys
    |> Enum.reduce(%{}, fn key, acc ->
      v1 = Map.get(map1, key, :__missing__)
      v2 = Map.get(map2, key, :__missing__)

      case compare_values(v1, v2) do
        res when res in [nil, %{}] -> acc
        res -> Map.put(acc, key, res)
      end
    end)
  end

  defp compare_values(v1, v2) do
    cond do
      v1 == v2 -> nil
      is_map(v1) and is_map(v2) -> diff(v1, v2)
      true -> true
    end
  end
end
