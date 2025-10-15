defmodule LiveDebugger.App.Utils.TermDiffer do
  @primitive_key :live_debugger_primitive_key

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
        ins: %{#{@primitive_key} => 2},
        del: %{#{@primitive_key} => 1},
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
            ins: %{#{@primitive_key} => 4},
            del: %{#{@primitive_key} => 3},
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

    @type type() :: :map | :list | :tuple | :struct | :primitive | :equal
    @type key() :: any()

    @type t() :: %__MODULE__{
            type: type(),
            ins: %{key() => term()},
            del: %{key() => term()},
            diff: %{key() => t()}
          }
  end

  @doc """
  Key for getting values in `ins` and `del` for `primitive` type.
  """
  def primitive_key, do: @primitive_key

  @doc """
  Returns the new value for `primitive` type.
  """
  @spec primitive_new_value(Diff.t()) :: term()
  def primitive_new_value(%Diff{type: :primitive, ins: %{@primitive_key => new_value}}) do
    new_value
  end

  @doc """
  Calculates the diff between two terms.
  """
  @spec diff(term(), term()) :: Diff.t()
  def diff(term, term), do: %Diff{type: :equal}

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
      ins: %{@primitive_key => struct2},
      del: %{@primitive_key => struct1}
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
      ins: %{@primitive_key => new_value},
      del: %{@primitive_key => old_value}
    }
  end

  defp list_diffs(list1, list2) when is_list(list1) and is_list(list2) do
    list1_with_indexes = Enum.with_index(list1, fn value, index -> {index, value} end)
    list2_with_indexes = Enum.with_index(list2, fn value, index -> {index, value} end)

    myers_diff =
      List.myers_difference(list1, list2)
      |> Enum.map(fn {type, values} -> {type, Enum.count(values)} end)

    initial_state =
      %{
        list1: list1_with_indexes,
        list2: list2_with_indexes,
        inserts: [],
        deletes: []
      }

    %{inserts: inserts, deletes: deletes} =
      Enum.reduce(myers_diff, initial_state, fn
        {:eq, count}, acc ->
          list1_acc = Enum.drop(acc.list1, count)
          list2_acc = Enum.drop(acc.list2, count)
          %{acc | list1: list1_acc, list2: list2_acc}

        {:ins, count}, acc ->
          inserts = acc.inserts ++ Enum.take(acc.list2, count)
          list2_acc = Enum.drop(acc.list2, count)
          %{acc | inserts: inserts, list2: list2_acc}

        {:del, count}, acc ->
          deletes = acc.deletes ++ Enum.take(acc.list1, count)
          list1_acc = Enum.drop(acc.list1, count)
          %{acc | deletes: deletes, list1: list1_acc}
      end)

    {Enum.into(inserts, %{}), Enum.into(deletes, %{})}
  end

  defp map_diffs(map1, map2) when is_map(map1) and is_map(map2) do
    ins = Map.drop(map2, Map.keys(map1))
    del = Map.drop(map1, Map.keys(map2))

    diff =
      Map.intersect(map1, map2, fn _, old_value, new_value ->
        diff(old_value, new_value)
      end)
      |> Map.reject(fn {_, value} -> match?(%Diff{type: :equal}, value) end)

    {ins, del, diff}
  end
end
