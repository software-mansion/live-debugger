defmodule LiveDebugger.App.Utils.TermDiffer do
  @moduledoc """
  Module for getting diffs between two terms.

  `Diff` struct contains information about all changes with values.
  It has fields:
  - `:type` - type of the diff
  - `:ins` - map of inserted values with keys (indexes for lists, keys for maps, etc.)
  - `:del` - map of deleted values with keys (indexes for lists, keys for maps, etc.)
  - `:diff` - map of diffs for each key with recursive `Diff` structs

  It has type `:primitive` for leaf diff values.
  `:ins` contains only `:primitive` field with the new value.
  `:del` contains only `:primitive` field with the old value.


  ## Examples

      iex> TermDiffer.diff(1, 2)
      %TermDiffer.Diff{
        type: :primitive,
        ins: %{primitive: 2},
        del: %{primitive: 1},
      }

      iex> TermDiffer.diff([1, 2, 3], [4, 2, 3])
      %TermDiffer.Diff{
        type: :list,
        ins: %{0 => 4},
        del: %{0 => 1},
        diff: %{}
      }

      iex> TermDiffer.diff(%{a: 1, b: 2, c: 3}, %{a: 1, b: 2, c: 4})
      %TermDiffer.Diff{
        type: :map,
        ins: %{},
        del: %{},
        diff: %{
          c: %TermDiffer.Diff{
            type: :primitive,
            ins: %{primitive: 4},
            del: %{primitive: 3},
            diff: %{}
          }
        }
      }
  """

  defmodule Diff do
    @moduledoc """
    Struct for representing a diff between two terms.
    """

    defstruct [:type, ins: %{}, del: %{}, diff: %{}]

    @type type() :: :map | :list | :tuple | :struct | :primitive
    @type key() :: any()

    @type t() :: %__MODULE__{
            type: type(),
            ins: %{key() => term()},
            del: %{key() => term()},
            diff: %{key() => t()}
          }
  end

  @doc """
  Calculates the diff between two terms.
  """
  @spec diff(term(), term()) :: Diff.t() | nil
  def diff(term, term), do: nil

  def diff(list1, list2) when is_list(list1) and is_list(list2) do
    {ins, del} = list_diffs(list1, list2)

    %Diff{type: :list, ins: ins, del: del}
  end

  def diff(%struct{} = struct1, %struct{} = struct2) do
    map1 = Map.from_struct(struct1)
    map2 = Map.from_struct(struct2)
    {_, _, diff} = map_diffs(map1, map2)

    %Diff{type: :struct, diff: diff}
  end

  def diff(struct1, struct2) when is_struct(struct1) and is_struct(struct2) do
    %Diff{
      type: :primitive,
      ins: %{primitive: struct2},
      del: %{primitive: struct1}
    }
  end

  def diff(map1, map2) when is_map(map1) and is_map(map2) do
    {ins, del, diff} = map_diffs(map1, map2)

    %Diff{type: :map, ins: ins, del: del, diff: diff}
  end

  def diff(tuple1, tuple2) when is_tuple(tuple1) and is_tuple(tuple2) do
    list1 = Tuple.to_list(tuple1)
    list2 = Tuple.to_list(tuple2)

    {ins, del} = list_diffs(list1, list2)

    %Diff{type: :tuple, ins: ins, del: del}
  end

  def diff(old_value, new_value) do
    %Diff{
      type: :primitive,
      ins: %{primitive: new_value},
      del: %{primitive: old_value}
    }
  end

  defp list_diffs(list1, list2) when is_list(list1) and is_list(list2) do
    list1_with_indexes = Enum.with_index(list1, fn value, index -> {index, value} end)
    list2_with_indexes = Enum.with_index(list2, fn value, index -> {index, value} end)

    diffs = List.myers_difference(list1, list2)

    {_, _, inserts, deletes} =
      Enum.reduce(diffs, {list1_with_indexes, list2_with_indexes, [], []}, fn {type, values},
                                                                              {list1_acc,
                                                                               list2_acc, ins_acc,
                                                                               del_acc} ->
        count = Enum.count(values)

        case type do
          :eq ->
            list1_acc = Enum.drop(list1_acc, count)
            list2_acc = Enum.drop(list2_acc, count)
            {list1_acc, list2_acc, ins_acc, del_acc}

          :ins ->
            ins_acc = ins_acc ++ Enum.take(list2_acc, count)
            list2_acc = Enum.drop(list2_acc, count)
            {list1_acc, list2_acc, ins_acc, del_acc}

          :del ->
            del_acc = del_acc ++ Enum.take(list1_acc, count)
            list1_acc = Enum.drop(list1_acc, count)
            {list1_acc, list2_acc, ins_acc, del_acc}
        end
      end)

    {Enum.into(inserts, %{}), Enum.into(deletes, %{})}
  end

  defp map_diffs(map1, map2) when is_map(map1) and is_map(map2) do
    ins = map2 |> Enum.filter(fn {key, _} -> not Map.has_key?(map1, key) end) |> Enum.into(%{})
    del = map1 |> Enum.filter(fn {key, _} -> not Map.has_key?(map2, key) end) |> Enum.into(%{})

    diff =
      map1
      |> Enum.filter(fn {key, _} -> Map.has_key?(map2, key) end)
      |> Enum.map(fn {key, value} ->
        diff = diff(value, Map.fetch!(map2, key))
        {key, diff}
      end)
      |> Enum.filter(fn {_, diff} -> diff !== nil end)
      |> Enum.into(%{})

    {ins, del, diff}
  end
end
