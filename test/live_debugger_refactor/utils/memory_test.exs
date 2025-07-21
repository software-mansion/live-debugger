defmodule LiveDebuggerRefactor.Utils.MemoryTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Utils.Memory

  describe "term_size/1" do
    test "returns the size of an elixir term in bytes" do
      term = 1123
      assert 6 = Memory.term_size(term)

      term = "Hello, World!"
      assert 19 = Memory.term_size(term)
    end
  end
end
