defmodule LiveDebuggerTest do
  use ExUnit.Case
  doctest LiveDebugger

  test "greets the world" do
    assert LiveDebugger.hello() == :world
  end
end
