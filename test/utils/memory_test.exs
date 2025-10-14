defmodule LiveDebugger.Utils.MemoryTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Utils.Memory

  describe "serialized_term_size/1" do
    test "returns the size of an elixir term serialized to binary in bytes" do
      assert 3 = Memory.serialized_term_size(42)
      assert 11 = Memory.serialized_term_size("Hello")
      assert 9 = Memory.serialized_term_size([1, 2, 3, 4, 5])
      assert 21 = Memory.serialized_term_size(%{key: "value"})
      assert 3 = Memory.serialized_term_size(1)
      assert 14 = Memory.serialized_term_size([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    end

    test "returns specific sizes for nil and integers" do
      assert 6 = Memory.serialized_term_size(nil)
      assert 3 = Memory.serialized_term_size(0)
      assert 3 = Memory.serialized_term_size(1)
      assert 3 = Memory.serialized_term_size(42)
      assert 6 = Memory.serialized_term_size(1123)
    end

    test "returns specific sizes for strings" do
      assert 19 = Memory.serialized_term_size("Hello, World!")
      assert 11 = Memory.serialized_term_size("Hello")
    end
  end

  describe "term_heap_size/1" do
    test "returns the size of an elixir term stored in the process heap in bytes" do
      assert 0 = Memory.term_heap_size(42)
      assert 24 = Memory.term_heap_size("Hello")
      assert 80 = Memory.term_heap_size([1, 2, 3, 4, 5])
      assert 72 = Memory.term_heap_size(%{key: "value"})
      assert 0 = Memory.term_heap_size(1)
      assert 160 = Memory.term_heap_size([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    end

    test "returns zero for nil and small integers" do
      assert 0 = Memory.term_heap_size(nil)
      assert 0 = Memory.term_heap_size(0)
      assert 0 = Memory.term_heap_size(1)
      assert 0 = Memory.term_heap_size(42)
    end
  end

  describe "bytes_to_pretty_string/1" do
    test "formats bytes correctly" do
      assert "0B" = Memory.bytes_to_pretty_string(0)
      assert "1B" = Memory.bytes_to_pretty_string(1)
      assert "1023B" = Memory.bytes_to_pretty_string(1023)
    end

    test "formats kilobytes correctly" do
      assert "1.0KB" = Memory.bytes_to_pretty_string(1024)
      assert "1.5KB" = Memory.bytes_to_pretty_string(1536)
      assert "1023.0KB" = Memory.bytes_to_pretty_string(1_047_552)
    end

    test "formats megabytes correctly" do
      assert "1.0MB" = Memory.bytes_to_pretty_string(1_048_576)
      assert "1.5MB" = Memory.bytes_to_pretty_string(1_572_864)
      assert "1023.0MB" = Memory.bytes_to_pretty_string(1_072_693_248)
    end

    test "formats gigabytes correctly" do
      assert "1.00GB" = Memory.bytes_to_pretty_string(1_073_741_824)
      assert "1.50GB" = Memory.bytes_to_pretty_string(1_610_612_736)
      assert "2.34GB" = Memory.bytes_to_pretty_string(2_512_365_404)
    end
  end
end
