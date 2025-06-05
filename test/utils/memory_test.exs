defmodule LiveDebugger.Utils.MemoryTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Utils.Memory

  describe "table_size/1" do
    test "returns the memory size of an ETS table in bytes" do
      table = :ets.new(:test_table, [:public])
      # Initial size of an empty ETS table
      initial_size = Memory.table_size(table)

      assert initial_size >= 0
      :ets.insert(table, {:key, "value"})

      size = Memory.table_size(table)

      assert size - initial_size == 80
      :ets.delete(table)
    end

    test "returns 0 ig there is no ETS table" do
      table = :non_existing_table
      assert Memory.table_size(table) == 0
    end
  end

  describe "term_size/1" do
    test "returns the size of an elixir term in bytes" do
      term = 1123
      assert 6 = Memory.term_size(term)

      term = "Hello, World!"
      assert 19 = Memory.term_size(term)
    end
  end
end
