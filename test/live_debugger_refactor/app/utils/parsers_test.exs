defmodule LiveDebuggerRefactor.App.Utils.ParsersTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.App.Utils.Parsers

  test "pid_to_string/1 converts pid to string" do
    pid = :c.pid(0, 123, 0)
    assert Parsers.pid_to_string(pid) == "0.123.0"
  end
end
