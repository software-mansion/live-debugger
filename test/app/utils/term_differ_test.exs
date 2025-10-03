defmodule LiveDebugger.App.Utils.TermDifferTest do
  use ExUnit.Case

  alias LiveDebugger.App.Utils.TermDiffer

  defmodule TestStruct1 do
    defstruct [:a, :b, :c]
  end

  defmodule TestStruct2 do
    defstruct [:a, :b, :c]
  end

  describe "diff/2" do
    test "returns a diff between two primitive terms" do
      assert TermDiffer.diff(1, 2) == %TermDiffer.Diff{
               type: :primitive,
               ins: [],
               del: [],
               diff: nil
             }
    end

    test "returns a diff between two lists with ins and del" do
      assert TermDiffer.diff([1, 2, 3, 4], [5, 1, 2, 3]) == %TermDiffer.Diff{
               type: :list,
               ins: [0],
               del: [3],
               diff: nil
             }
    end

    test "returns ins and del when element in list changed" do
      assert TermDiffer.diff([1, 2, 3, 4], [1, 2, 3, 5]) == %TermDiffer.Diff{
               type: :list,
               ins: [3],
               del: [3],
               diff: nil
             }
    end

    test "returns a diff between two maps with different keys" do
      assert TermDiffer.diff(%{a: 1, b: 2, c: 4}, %{a: 1, b: 2, d: 4}) == %TermDiffer.Diff{
               type: :map,
               ins: [:d],
               del: [:c],
               diff: nil
             }
    end

    test "returns a diff between two maps with changed values" do
      assert TermDiffer.diff(%{a: 1, b: 2, c: 4}, %{a: 1, b: 2, c: 5}) == %TermDiffer.Diff{
               type: :map,
               ins: [],
               del: [],
               diff: %{c: %TermDiffer.Diff{type: :primitive, ins: [], del: [], diff: nil}}
             }
    end

    test "returns a diff between two tuples with different values" do
      assert TermDiffer.diff({1, 2, 3, 4}, {2, 3, 5}) == %TermDiffer.Diff{
               type: :tuple,
               ins: [2],
               del: [3, 0],
               diff: nil
             }
    end

    test "returns a diff between two structs with different values" do
      assert TermDiffer.diff(%TestStruct1{a: 1, b: 2, c: 4}, %TestStruct1{a: 1, b: 2, c: 5}) ==
               %TermDiffer.Diff{
                 type: :struct,
                 ins: [],
                 del: [],
                 diff: %{c: %TermDiffer.Diff{type: :primitive, ins: [], del: [], diff: nil}}
               }
    end

    test "returns a primitive diff when the structs are not the same" do
      assert TermDiffer.diff(%TestStruct1{a: 1, b: 2, c: 4}, %TestStruct2{a: 1, b: 2, c: 4}) ==
               %TermDiffer.Diff{
                 type: :primitive,
                 ins: [],
                 del: [],
                 diff: nil
               }
    end

    test "works properly with nested data types" do
      term1 = %{
        list: [1, 2, 3, 4],
        map: %{a: 1, b: 2, c: 3},
        struct: %TestStruct1{a: 1, b: 2, c: 3},
        tuple: {1, 2, 3, 4},
        primitive1: 1,
        nested_map: %{
          list: [1, 2],
          tuple: {4, 4, 5, 4, 4}
        }
      }

      term2 = %{
        list: [1, 2, 3, 5],
        map: %{a: 1, b: 2, c: 3},
        struct: nil,
        tuple: {1, 2, 3, 4},
        primitive2: 1,
        nested_map: %{
          list: [1, 2],
          tuple: {4, 4, 4, 4, 5}
        }
      }

      assert %TermDiffer.Diff{
               type: :map,
               ins: [:primitive2],
               del: [:primitive1],
               diff: %{
                 list: %TermDiffer.Diff{
                   type: :list,
                   ins: [3],
                   del: [3]
                 },
                 struct: %TermDiffer.Diff{type: :primitive},
                 nested_map: %TermDiffer.Diff{
                   type: :map,
                   diff: %{
                     tuple: %TermDiffer.Diff{type: :tuple, ins: [4], del: [2]}
                   }
                 }
               }
             } = TermDiffer.diff(term1, term2)
    end
  end

  describe "diff_to_id_list/2" do
    test "returns a list of ids for a diff" do
      term1 = %{a: 1, b: 2, c: %{d: 3}}
      term2 = %{a: 1, b: 2, c: %{d: 4}}

      diff = TermDiffer.diff(term1, term2)

      assert TermDiffer.diff_to_id_list(term2, diff) == ["root", "root.2", "root.2.0"]
    end

    test "works properly with structs" do
      term1 = %TestStruct1{a: 1, b: 2, c: 3}
      term2 = %TestStruct1{a: 1, b: 2, c: 4}

      diff = TermDiffer.diff(term1, term2)

      assert TermDiffer.diff_to_id_list(term2, diff) == ["root", "root.2"]
    end

    test "works properly with tuples" do
      term1 = {1, 2, 3}
      term2 = {1, 2, 4}

      diff = TermDiffer.diff(term1, term2)

      assert TermDiffer.diff_to_id_list(term2, diff) == ["root", "root.2"]
    end

    test "works properly with lists" do
      term1 = [1, 2, 3]
      term2 = [1, 2, 4]

      diff = TermDiffer.diff(term1, term2)

      assert TermDiffer.diff_to_id_list(term2, diff) == ["root", "root.2"]
    end

    test "works properly with maps" do
      term1 = %{a: 1, c: 3, d: 4}
      term2 = %{a: 1, b: 2, d: 4}

      diff = TermDiffer.diff(term1, term2)

      assert TermDiffer.diff_to_id_list(term2, diff) == ["root", "root.1"]
    end
  end
end
