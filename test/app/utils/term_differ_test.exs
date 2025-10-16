defmodule LiveDebugger.App.Utils.TermDifferTest do
  use ExUnit.Case

  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermDiffer.Diff
  alias LiveDebugger.Fakes

  defmodule TestStruct1 do
    @moduledoc false
    defstruct [:a, :b, :c]
  end

  defmodule TestStruct2 do
    @moduledoc false
    defstruct [:a, :b, :c]
  end

  describe "diff/2" do
    test "returns an equal diff when the terms are the same" do
      assert TermDiffer.diff(1, 1) == Fakes.term_diff(type: :equal)
    end

    test "returns a diff between two primitive terms" do
      assert TermDiffer.diff(1, 2) == Fakes.term_diff_primitive(old_value: 1, new_value: 2)
    end

    test "returns primitive diff for different data types" do
      assert TermDiffer.diff(1, %{a: 1}) ==
               Fakes.term_diff_primitive(old_value: 1, new_value: %{a: 1})
    end

    test "returns a diff between two lists with ins and del" do
      assert TermDiffer.diff([1, 2, 3, 4], [5, 1, 2, 3]) ==
               Fakes.term_diff(type: :list, ins: %{0 => 5}, del: %{3 => 4})
    end

    test "returns ins and del when element in list changed" do
      assert TermDiffer.diff([1, 2, 3, 4], [1, 2, 3, 5]) ==
               Fakes.term_diff(type: :list, ins: %{3 => 5}, del: %{3 => 4})
    end

    test "returns a diff between two tuples with different values" do
      assert TermDiffer.diff({1, 2, 3, 4}, {2, 3, 5}) ==
               Fakes.term_diff(type: :tuple, ins: %{2 => 5}, del: %{3 => 4, 0 => 1})
    end

    test "returns proper indexes for inserted and deleted values" do
      assert TermDiffer.diff([1, 2, 3, 4, 5], [1, 1.5, 2, 4, 4.5, 5]) ==
               Fakes.term_diff(type: :list, ins: %{1 => 1.5, 4 => 4.5}, del: %{2 => 3})
    end

    test "returns a diff between two maps with different keys" do
      assert TermDiffer.diff(%{a: 1, b: 2, c: 4}, %{a: 1, b: 2, d: 4}) ==
               Fakes.term_diff(type: :map, ins: %{:d => 4}, del: %{:c => 4})
    end

    test "returns a diff between two maps with changed values" do
      assert TermDiffer.diff(%{a: 1, b: 2, c: 4}, %{a: 1, b: 2, c: 5}) ==
               Fakes.term_diff(
                 type: :map,
                 diff: %{c: Fakes.term_diff_primitive(old_value: 4, new_value: 5)}
               )
    end

    test "returns a diff between two structs with different values" do
      assert TermDiffer.diff(%TestStruct1{a: 1, b: 2, c: 4}, %TestStruct1{a: 1, b: 2, c: 5}) ==
               Fakes.term_diff(
                 type: :struct,
                 diff: %{c: Fakes.term_diff_primitive(old_value: 4, new_value: 5)}
               )
    end

    test "returns a primitive diff when the structs are not the same" do
      assert TermDiffer.diff(%TestStruct1{a: 1, b: 2, c: 4}, %TestStruct2{a: 1, b: 2, c: 4}) ==
               Fakes.term_diff_primitive(
                 old_value: %TestStruct1{a: 1, b: 2, c: 4},
                 new_value: %TestStruct2{a: 1, b: 2, c: 4}
               )
    end

    test "works properly with nested data types" do
      primitive_key = :live_debugger_primitive_key

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
                   ins: %{^primitive_key => nil},
                   del: %{^primitive_key => %TestStruct1{a: 1, b: 2, c: 3}}
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
