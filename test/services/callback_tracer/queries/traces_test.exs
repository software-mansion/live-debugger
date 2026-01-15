defmodule Services.CallbackTracer.Queries.TracesTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.CallbackTracer.Queries.Traces, as: TraceQueries
  alias LiveDebugger.MockAPITracesStorage

  setup :verify_on_exit!

  describe "get_last_trace_id" do
    test "returns 1 if no traces table present" do
      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [] end)

      assert 1 == TraceQueries.get_last_trace_id()
    end

    test "filters out :\"$end_of_table\"" do
      pid1 = :c.pid(0, 1, 0)
      pid2 = :c.pid(0, 2, 0)
      table1 = :ets.new(:table1, [:ordered_set, :public])
      table2 = :ets.new(:table2, [:ordered_set, :public])

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}, {pid2, table2}] end)

      assert 1 == TraceQueries.get_last_trace_id()
    end

    test "returns smallest id present" do
      pid1 = :c.pid(0, 1, 0)
      pid2 = :c.pid(0, 2, 0)
      table1 = :ets.new(:table1, [:ordered_set, :public])
      table2 = :ets.new(:table2, [:ordered_set, :public])
      :ets.insert(table1, {-1, :trace})
      :ets.insert(table1, {-3, :trace})
      :ets.insert(table2, {-8, :trace})
      :ets.insert(table2, {-18, :trace})

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [{pid1, table1}, {pid2, table2}] end)

      assert -18 == TraceQueries.get_last_trace_id()
    end
  end
end
