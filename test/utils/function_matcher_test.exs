defmodule LiveDebugger.Utils.FunctionMatcherTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Utils.FunctionMatcher
  alias LiveDebugger.Structs.Trace.FunctionTrace.SourceLocation

  describe "find_matching_clause_line/3" do
    test "returns source location for a simple function" do
      args = [%{counter: 0}]

      assert {:ok, %SourceLocation{source_file: file, line: line}} =
               FunctionMatcher.find_matching_clause_line(
                 LiveDebuggerDev.LiveViews.Main,
                 :render,
                 args
               )

      assert is_binary(file)
      assert String.ends_with?(file, "dev/live_views/main.ex")
      assert is_integer(line)
      assert line > 0
    end

    test "matches the correct clause when guards are present" do
      socket = %Phoenix.LiveView.Socket{}

      assert {:ok, %SourceLocation{line: guarded_line}} =
               FunctionMatcher.find_matching_clause_line(
                 LiveDebuggerDev.LiveViews.Main,
                 :handle_event,
                 ["increment", %{}, socket]
               )

      assert {:ok, %SourceLocation{line: string_line}} =
               FunctionMatcher.find_matching_clause_line(
                 LiveDebuggerDev.LiveViews.Main,
                 :handle_event,
                 ["increment", %{}, "a string socket"]
               )

      assert string_line < guarded_line
    end

    test "matches different clauses based on pattern matching" do
      socket = %Phoenix.LiveView.Socket{}

      assert {:ok, %SourceLocation{line: increment_line}} =
               FunctionMatcher.find_matching_clause_line(
                 LiveDebuggerDev.LiveViews.Main,
                 :handle_event,
                 ["increment", %{}, socket]
               )

      assert {:ok, %SourceLocation{line: slow_line}} =
               FunctionMatcher.find_matching_clause_line(
                 LiveDebuggerDev.LiveViews.Main,
                 :handle_event,
                 ["slow-increment", %{}, socket]
               )

      assert increment_line != slow_line
    end

    test "returns the same file path for all clauses of the same module" do
      socket = %Phoenix.LiveView.Socket{}

      assert {:ok, %SourceLocation{source_file: file1}} =
               FunctionMatcher.find_matching_clause_line(
                 LiveDebuggerDev.LiveViews.Main,
                 :render,
                 [%{counter: 0}]
               )

      assert {:ok, %SourceLocation{source_file: file2}} =
               FunctionMatcher.find_matching_clause_line(
                 LiveDebuggerDev.LiveViews.Main,
                 :handle_event,
                 ["increment", %{}, socket]
               )

      assert file1 == file2
    end

    test "returns error for non-existent module" do
      assert {:error, _} =
               FunctionMatcher.find_matching_clause_line(
                 NonExistentModule,
                 :foo,
                 []
               )
    end

    test "returns error for non-existent function" do
      assert {:error, _} =
               FunctionMatcher.find_matching_clause_line(
                 LiveDebuggerDev.LiveViews.Main,
                 :non_existent_function,
                 []
               )
    end

    test "returns error when no clause matches the given args" do
      assert {:error, :no_matching_clause} =
               FunctionMatcher.find_matching_clause_line(
                 LiveDebuggerDev.LiveViews.Main,
                 :handle_info,
                 [:unmatched_message, %Phoenix.LiveView.Socket{}]
               )
    end

    test "works with LiveComponent modules" do
      assigns = %{id: "test", myself: %Phoenix.LiveComponent.CID{cid: 1}}

      assert {:ok, %SourceLocation{source_file: file, line: line}} =
               FunctionMatcher.find_matching_clause_line(
                 LiveDebuggerDev.LiveComponents.Name,
                 :update,
                 [assigns, %Phoenix.LiveView.Socket{}]
               )

      assert String.ends_with?(file, "dev/live_components/name.ex")
      assert line > 0
    end
  end
end
