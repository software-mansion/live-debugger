defmodule LiveDebugger.App.Utils.TermDiffer do
  @moduledoc """
  Module for getting diffs between two terms.
  """

  defmodule Diff do
    @moduledoc """
    Struct for representing a diff between two terms.
    """

    defstruct [:type, ins: [], del: [], diff: nil]

    @type type() :: :map | :list | :tuple | :struct | :primitive
    @type t() ::
            %__MODULE__{
              type: type(),
              ins: [atom() | non_neg_integer()],
              del: [atom() | non_neg_integer()],
              diff: %{atom() => t()} | nil
            }
  end

  @doc """
  Converts a diff to a list of ids used by TermParser.
  """
  @spec diff_to_id_list(term(), Diff.t()) :: [String.t()]
  def diff_to_id_list(term, diff, path \\ "root")

  def diff_to_id_list(_, %Diff{type: type, ins: ins}, path)
      when type in [:list, :tuple] do
    [path | Enum.map(ins, fn index -> "#{path}.#{index}" end)]
  end

  def diff_to_id_list(term, %Diff{type: :map, ins: ins, diff: diffs}, path) do
    keys_with_ids = term |> Map.keys() |> Enum.sort()

    diff_ids = nested_diff_ids(diffs, term, keys_with_ids, path)

    ins_ids =
      Enum.map(ins, fn key ->
        index = Enum.find_index(keys_with_ids, &(&1 === key))
        if is_nil(index), do: raise("Key #{key} not found in #{inspect(term)}")

        "#{path}.#{index}"
      end)

    [path] ++ ins_ids ++ diff_ids
  end

  def diff_to_id_list(term, %Diff{type: :struct, diff: diffs}, path) do
    map_term = term |> Map.from_struct()
    keys_with_ids = map_term |> Map.keys() |> Enum.sort()

    [path] ++ nested_diff_ids(diffs, map_term, keys_with_ids, path)
  end

  def diff_to_id_list(_, %Diff{type: :primitive}, path), do: [path]

  @spec diff(term(), term()) :: Diff.t() | nil
  def diff(term1, term2) when term1 === term2, do: nil

  def diff(list1, list2) when is_list(list1) and is_list(list2) do
    {ins, del} = do_list_index_diff(list1, list2)

    %Diff{type: :list, ins: ins, del: del}
  end

  def diff(%struct{} = struct1, %struct{} = struct2) do
    map1 = Map.from_struct(struct1)
    map2 = Map.from_struct(struct2)
    {_, _, diff} = do_map_index_diff(map1, map2)

    %Diff{type: :struct, diff: diff}
  end

  def diff(struct1, struct2) when is_struct(struct1) and is_struct(struct2) do
    %Diff{type: :primitive}
  end

  def diff(map1, map2) when is_map(map1) and is_map(map2) do
    {ins, del, diff} = do_map_index_diff(map1, map2)

    %Diff{type: :map, ins: ins, del: del, diff: diff}
  end

  def diff(tuple1, tuple2) when is_tuple(tuple1) and is_tuple(tuple2) do
    list1 = Tuple.to_list(tuple1)
    list2 = Tuple.to_list(tuple2)

    {ins, del} = do_list_index_diff(list1, list2)

    %Diff{type: :tuple, ins: ins, del: del}
  end

  def diff(_, _), do: %Diff{type: :primitive}

  defp nested_diff_ids(nil, _term, _keys_with_ids, _path), do: []

  defp nested_diff_ids(diffs, map_term, keys_with_ids, path)
       when is_map(diffs) and is_map(map_term) do
    diffs
    |> Enum.map(fn {key, diff} ->
      index = Enum.find_index(keys_with_ids, &(&1 === key))
      if is_nil(index), do: raise("Key #{key} not found in #{inspect(map_term)}")
      sub_term = Map.fetch!(map_term, key)

      diff_to_id_list(sub_term, diff, "#{path}.#{index}")
    end)
    |> List.flatten()
  end

  defp do_list_index_diff(list1, list2) when is_list(list1) and is_list(list2) do
    diffs =
      list1
      |> List.myers_difference(list2)
      |> Enum.group_by(fn {key, _} -> key end, fn {_, values} -> values end)

    ins_values = diffs |> Map.get(:ins, []) |> List.flatten()
    del_values = diffs |> Map.get(:del, []) |> List.flatten()

    ins_indexes = indexes_from_values(ins_values, list2)
    del_indexes = indexes_from_values(del_values, list1)

    {ins_indexes, del_indexes}
  end

  defp indexes_from_values(values, list) when is_list(values) and is_list(list) do
    {indexes, _} =
      Enum.reduce(values, {[], list}, fn value, {indexes, list} ->
        index = Enum.find_index(list, &(&1 === value))

        values = List.replace_at(list, index, :live_debugger_value_used)

        {[index | indexes], values}
      end)

    indexes
  end

  defp do_map_index_diff(map1, map2) when is_map(map1) and is_map(map2) do
    map1_keys = map1 |> Map.keys() |> MapSet.new()
    map2_keys = map2 |> Map.keys() |> MapSet.new()

    keys_del = MapSet.difference(map1_keys, map2_keys) |> MapSet.to_list() |> Enum.sort()
    keys_ins = MapSet.difference(map2_keys, map1_keys) |> MapSet.to_list() |> Enum.sort()
    keys_diff = MapSet.intersection(map1_keys, map2_keys) |> MapSet.to_list() |> Enum.sort()

    keys_diff_map =
      keys_diff
      |> Enum.map(fn key ->
        value1 = Map.fetch!(map1, key)
        value2 = Map.fetch!(map2, key)

        diff = diff(value1, value2)

        {key, diff}
      end)
      |> Enum.filter(fn {_, diff} -> diff !== nil end)
      |> case do
        [] -> nil
        diffs -> Enum.into(diffs, %{})
      end

    {keys_ins, keys_del, keys_diff_map}
  end
end
