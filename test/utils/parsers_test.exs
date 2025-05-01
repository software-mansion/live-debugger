defmodule LiveDebugger.Utils.ParsersTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Utils.Parsers

  describe "parse_timestamp/1" do
    test "parses a valid timestamp" do
      timestamp = 1_000_000
      assert Parsers.parse_timestamp(timestamp) == "00:00:01.000000"
    end

    test "returns \"Invalid timestamp\" when timestamp is invalid" do
      timestamp = 109_201_930_129_391_238_012_983_091_283_712_097_380_127
      assert Parsers.parse_timestamp(timestamp) == "Invalid timestamp"
    end
  end

  describe "parse_elapsed_time/1" do
    test "parses microseconds for less than 1ms" do
      assert Parsers.parse_elapsed_time(500) == "500 µs"
    end

    test "parses milliseconds" do
      assert Parsers.parse_elapsed_time(1_500) == "1 ms"
    end

    test "parses seconds" do
      assert Parsers.parse_elapsed_time(1_500_000) == "1.50 s"
    end
  end

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

  describe "string_to_cid/1" do
    test "converts string to cid" do
      cid = %Phoenix.LiveComponent.CID{cid: 123}
      assert {:ok, ^cid} = Parsers.string_to_cid("123")
    end

    test "returns :error for invalid string" do
      assert Parsers.string_to_cid("invalid") == :error
    end
  end

  test "module_to_string/1 converts module to string" do
    assert Parsers.module_to_string(LiveDebuggerTest.TestView) == "LiveDebuggerTest.TestView"
  end
end
