defmodule LiveDebugger.App.Utils.TermDifferTest do
  use ExUnit.Case

  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermDiffer.Diff

  defmodule TestStruct1 do
    defstruct [:a, :b, :c]
  end

  defmodule TestStruct2 do
    defstruct [:a, :b, :c]
  end

  describe "diff/2" do
    test "returns a diff between two primitive terms" do
      assert TermDiffer.diff(1, 2) == %Diff{
               type: :primitive,
               ins: %{primitive: 2},
               del: %{primitive: 1},
               diff: %{}
             }
    end

    test "returns primitive diff for different data types" do
      assert TermDiffer.diff(1, %{a: 1}) == %Diff{
               type: :primitive,
               ins: %{primitive: %{a: 1}},
               del: %{primitive: 1},
               diff: %{}
             }
    end

    test "returns a diff between two lists with ins and del" do
      assert TermDiffer.diff([1, 2, 3, 4], [5, 1, 2, 3]) == %Diff{
               type: :list,
               ins: %{0 => 5},
               del: %{3 => 4},
               diff: %{}
             }
    end

    test "returns ins and del when element in list changed" do
      assert TermDiffer.diff([1, 2, 3, 4], [1, 2, 3, 5]) == %Diff{
               type: :list,
               ins: %{3 => 5},
               del: %{3 => 4},
               diff: %{}
             }
    end

    test "returns a diff between two tuples with different values" do
      assert TermDiffer.diff({1, 2, 3, 4}, {2, 3, 5}) == %Diff{
               type: :tuple,
               ins: %{2 => 5},
               del: %{3 => 4, 0 => 1},
               diff: %{}
             }
    end

    test "returns proper indexes for inserted and deleted values" do
      assert TermDiffer.diff([1, 2, 3, 4, 5], [1, 1.5, 2, 4, 4.5, 5]) == %Diff{
               type: :list,
               ins: %{1 => 1.5, 4 => 4.5},
               del: %{2 => 3},
               diff: %{}
             }
    end

    test "returns a diff between two maps with different keys" do
      assert TermDiffer.diff(%{a: 1, b: 2, c: 4}, %{a: 1, b: 2, d: 4}) == %Diff{
               type: :map,
               ins: %{:d => 4},
               del: %{:c => 4},
               diff: %{}
             }
    end

    test "returns a diff between two maps with changed values" do
      assert TermDiffer.diff(%{a: 1, b: 2, c: 4}, %{a: 1, b: 2, c: 5}) == %Diff{
               type: :map,
               ins: %{},
               del: %{},
               diff: %{
                 c: %Diff{
                   type: :primitive,
                   ins: %{primitive: 5},
                   del: %{primitive: 4},
                   diff: %{}
                 }
               }
             }
    end

    test "returns a diff between two structs with different values" do
      assert TermDiffer.diff(%TestStruct1{a: 1, b: 2, c: 4}, %TestStruct1{a: 1, b: 2, c: 5}) ==
               %Diff{
                 type: :struct,
                 ins: %{},
                 del: %{},
                 diff: %{
                   c: %Diff{
                     type: :primitive,
                     ins: %{primitive: 5},
                     del: %{primitive: 4},
                     diff: %{}
                   }
                 }
               }
    end

    test "returns a primitive diff when the structs are not the same" do
      assert TermDiffer.diff(%TestStruct1{a: 1, b: 2, c: 4}, %TestStruct2{a: 1, b: 2, c: 4}) ==
               %Diff{
                 type: :primitive,
                 ins: %{primitive: %TestStruct2{a: 1, b: 2, c: 4}},
                 del: %{primitive: %TestStruct1{a: 1, b: 2, c: 4}},
                 diff: %{}
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
          list: [1],
          tuple: {4, 4, 4, 4, 5},
          nested_element: :value
        }
      }

      assert %Diff{
               type: :map,
               ins: %{primitive2: 1},
               del: %{primitive1: 1},
               diff: %{
                 list: %Diff{
                   type: :list,
                   ins: %{3 => 5},
                   del: %{3 => 4}
                 },
                 struct: %Diff{
                   type: :primitive,
                   ins: %{primitive: nil},
                   del: %{primitive: %TestStruct1{a: 1, b: 2, c: 3}}
                 },
                 nested_map: %Diff{
                   type: :map,
                   ins: %{
                     nested_element: :value
                   },
                   diff: %{
                     tuple: %Diff{
                       type: :tuple,
                       ins: %{4 => 5},
                       del: %{2 => 5}
                     },
                     list: %Diff{
                       type: :list,
                       del: %{1 => 2}
                     }
                   }
                 }
               }
             } = TermDiffer.diff(term1, term2)
    end
  end
end
