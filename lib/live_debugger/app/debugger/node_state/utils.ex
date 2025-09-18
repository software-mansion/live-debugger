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

      cond do
        v1 == v2 ->
          acc

        is_map(v1) and is_map(v2) ->
          nested_diff = diff(v1, v2)

          if nested_diff == %{} do
            acc
          else
            Map.put(acc, key, nested_diff)
          end

        true ->
          Map.put(acc, key, true)
      end
    end)
  end

  def diff(_, _) do
    %{}
  end
end
