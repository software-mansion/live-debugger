defmodule LiveDebugger.Api.System.DbgTest do
  @moduledoc false
  use ExUnit.Case, async: true

  describe "flags_to_match_spec/1" do
    test "converts a single flag to match spec format" do
      assert [{:_, [], [{:return_trace}]}] =
               LiveDebugger.Api.System.Dbg.flags_to_match_spec(:return_trace)
    end

    test "converts multiple flags to match spec format" do
      assert [{:_, [], [{:return_trace}]}, {:_, [], [{:exception_trace}]}] =
               LiveDebugger.Api.System.Dbg.flags_to_match_spec([:return_trace, :exception_trace])
    end

    test "returns an empty list for no flags" do
      assert LiveDebugger.Api.System.Dbg.flags_to_match_spec([]) == []
    end

    test "exception for invalid flag" do
      assert_raise FunctionClauseError, fn ->
        LiveDebugger.Api.System.Dbg.flags_to_match_spec(:invalid_flag)
      end
    end
  end
end
