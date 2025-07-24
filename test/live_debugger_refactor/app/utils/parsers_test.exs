defmodule LiveDebuggerRefactor.App.Utils.ParsersTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.App.Utils.Parsers

  test "pid_to_string/1 converts pid to string" do
    pid = :c.pid(0, 123, 0)
    assert Parsers.pid_to_string(pid) == "0.123.0"
  end

  describe "string_to_pid/1" do
    test "converts string to pid" do
      pid = :c.pid(0, 123, 0)
      assert {:ok, ^pid} = Parsers.string_to_pid("0.123.0")
    end

    test "returns :error for invalid string" do
      assert Parsers.string_to_pid("invalid") == :error
    end
  end

  test "cid_to_string/1 converts cid to string" do
    cid = %Phoenix.LiveComponent.CID{cid: 123}
    assert Parsers.cid_to_string(cid) == "123"
  end

  test "module_to_string/1 converts module to string" do
    assert Parsers.module_to_string(LiveDebuggerTest.TestView) == "LiveDebuggerTest.TestView"
  end
end
