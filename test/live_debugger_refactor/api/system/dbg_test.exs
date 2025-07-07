defmodule LiveDebugger.API.System.DbgTest do
  @moduledoc false
  use ExUnit.Case, async: true

  describe "flag_to_match_spec/1" do
    test "converts a single flag to match spec format" do
      assert [{:_, [], [{:return_trace}]}] =
               LiveDebugger.API.System.Dbg.flag_to_match_spec(:return_trace)
    end

    test "exception for invalid flag" do
      assert_raise FunctionClauseError, fn ->
        LiveDebugger.API.System.Dbg.flag_to_match_spec(:invalid_flag)
      end
    end
  end
end
