defmodule Services.TraceServiceTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Fakes
  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.MockEtsTableServer

  @all_functions LiveDebugger.Utils.Callbacks.all_callbacks()
                 |> Enum.map(fn {function, arity} -> String.to_atom("#{function}/#{arity}") end)

  setup :verify_on_exit!

  setup_all do
    %{
      module: CoolApp.LiveViews.UserDashboard,
      pid: :c.pid(0, 0, 1)
    }
  end

  setup context do
    table = :ets.new(:trace_table, [:ordered_set, :public])

    Map.put(context, :table, table)
  end

  test "insert/1", %{module: module, pid: pid, table: table} do
    trace = Fakes.trace(id: 1, module: module, function: :render, pid: pid)

    MockEtsTableServer
    |> expect(:table, fn ^pid -> table end)

    assert true == TraceService.insert(trace)
    assert [{trace.id, trace}] == :ets.lookup(table, trace.id)
  end

  test "get/2", %{module: module, pid: pid, table: table} do
    trace1 = Fakes.trace(id: 1, module: module, function: :handle_info, pid: pid)
    trace2 = Fakes.trace(id: 2, module: module, function: :render, pid: pid)
    :ets.insert(table, {trace1.id, trace1})
    :ets.insert(table, {trace2.id, trace2})

    MockEtsTableServer
    |> expect(:table, 3, fn ^pid -> table end)

    assert trace1 == TraceService.get(pid, trace1.id)
    assert trace2 == TraceService.get(pid, trace2.id)
    assert nil == TraceService.get(pid, 99)
  end

  describe "existing_traces/2" do
    test "returns traces with default limit", %{module: module, pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, module: module, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, module: module, function: :render, arity: 1, pid: pid)
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      MockEtsTableServer
      |> expect(:table, fn ^pid -> table end)

      assert {[^trace1, ^trace2], _} =
               TraceService.existing_traces(pid, functions: @all_functions)
    end

    test "returns traces with limit and continuation", %{module: module, pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, module: module, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, module: module, function: :render, arity: 1, pid: pid)
      trace3 = Fakes.trace(id: 3, module: module, function: :handle_event, arity: 3, pid: pid)

      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      MockEtsTableServer
      |> expect(:table, fn ^pid -> table end)

      {traces1, cont} = TraceService.existing_traces(pid, limit: 2, functions: @all_functions)
      {traces2, cont} = TraceService.existing_traces(pid, cont: cont, functions: @all_functions)

      assert [trace1, trace2] == traces1
      assert [trace3] == traces2
      assert cont == :end_of_table

      assert :end_of_table == TraceService.existing_traces(pid, cont: :end_of_table)
    end

    test "raise ArgumentError when limit is less than 1", %{pid: pid} do
      assert_raise ArgumentError, fn -> TraceService.existing_traces(pid, limit: 0) end
      assert_raise ArgumentError, fn -> TraceService.existing_traces(pid, limit: -23) end
    end

    test "returns traces with functions filter", %{module: module, pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, module: module, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, module: module, function: :render, arity: 1, pid: pid)
      trace3 = Fakes.trace(id: 3, module: module, function: :handle_event, arity: 3, pid: pid)
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      MockEtsTableServer
      |> expect(:table, 2, fn ^pid -> table end)

      assert {[^trace1], _} = TraceService.existing_traces(pid, functions: [:"handle_info/2"])

      assert {[^trace1, ^trace2], _} =
               TraceService.existing_traces(pid,
                 functions: [:"handle_info/2", :"render/1", :"mount/1"]
               )
    end

    test "returns traces with execution time filter", %{module: module, pid: pid, table: table} do
      trace1 =
        Fakes.trace(
          id: 1,
          module: module,
          function: :handle_info,
          arity: 2,
          pid: pid,
          execution_time: 11
        )

      trace2 =
        Fakes.trace(
          id: 2,
          module: module,
          function: :render,
          arity: 1,
          pid: pid,
          execution_time: 25
        )

      trace3 =
        Fakes.trace(
          id: 3,
          module: module,
          function: :handle_event,
          arity: 3,
          pid: pid,
          execution_time: 100
        )

      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      MockEtsTableServer
      |> expect(:table, 2, fn ^pid -> table end)

      assert {[^trace2], _} =
               TraceService.existing_traces(pid,
                 execution_times: [exec_time_min: 15, exec_time_max: 50],
                 functions: @all_functions
               )

      assert {[^trace2, ^trace3], _} =
               TraceService.existing_traces(pid,
                 execution_times: [exec_time_min: 15, exec_time_max: :infinity],
                 functions: @all_functions
               )
    end

    test "returns traces with functions filter and execution time filter", %{
      module: module,
      pid: pid,
      table: table
    } do
      trace1 =
        Fakes.trace(
          id: 1,
          module: module,
          function: :handle_info,
          arity: 2,
          pid: pid,
          execution_time: 11
        )

      trace2 =
        Fakes.trace(
          id: 2,
          module: module,
          function: :render,
          arity: 1,
          pid: pid,
          execution_time: 25
        )

      trace3 =
        Fakes.trace(
          id: 3,
          module: module,
          function: :handle_event,
          arity: 3,
          pid: pid,
          execution_time: 100
        )

      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      MockEtsTableServer
      |> expect(:table, fn ^pid -> table end)

      assert {[^trace2], _} =
               TraceService.existing_traces(pid,
                 functions: [:"handle_info/2", :"render/1", :"mount/1"],
                 execution_times: [exec_time_min: 15, exec_time_max: 150]
               )
    end

    test "returns traces with node_id filter", %{module: module, pid: pid, table: table} do
      cid = %Phoenix.LiveComponent.CID{cid: 3}
      trace1 = Fakes.trace(id: 1, module: module, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, module: module, function: :render, arity: 1, pid: pid, cid: cid)

      trace3 =
        Fakes.trace(id: 3, module: module, function: :handle_event, arity: 3, pid: pid, cid: cid)

      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      MockEtsTableServer
      |> expect(:table, 2, fn ^pid -> table end)

      assert {[^trace1], _} =
               TraceService.existing_traces(pid, node_id: pid, functions: @all_functions)

      assert {[^trace2, ^trace3], _} =
               TraceService.existing_traces(pid, node_id: cid, functions: @all_functions)
    end

    test "returns :end_of_table when no traces match", %{module: module, pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, module: module, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, module: module, function: :render, arity: 1, pid: pid)
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      MockEtsTableServer
      |> expect(:table, fn ^pid -> table end)

      assert :end_of_table =
               TraceService.existing_traces(pid, functions: [:"non_existent/2"])
    end

    test "returns only finished traces", %{module: module, pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, module: module, function: :handle_info, arity: 2, pid: pid)

      trace2 =
        Fakes.trace(id: 2, module: module, function: :render, pid: pid, execution_time: nil)

      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      MockEtsTableServer
      |> expect(:table, fn ^pid -> table end)

      assert {[^trace1], _} = TraceService.existing_traces(pid, functions: @all_functions)
    end
  end

  describe "clear_traces/2" do
    test "clears traces for LiveView or LiveComponent", %{module: module, pid: pid, table: table} do
      cid = %Phoenix.LiveComponent.CID{cid: 3}

      trace1 = Fakes.trace(id: 1, module: module, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, module: module, function: :render, arity: 1, pid: pid, cid: cid)

      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      MockEtsTableServer
      |> expect(:table, 5, fn ^pid -> table end)

      assert {[^trace1, ^trace2], _} =
               TraceService.existing_traces(pid, functions: @all_functions)

      TraceService.clear_traces(pid, trace1.pid)

      assert {[^trace2], _} = TraceService.existing_traces(pid, functions: @all_functions)

      TraceService.clear_traces(pid, trace2.cid)

      assert :end_of_table = TraceService.existing_traces(pid, functions: @all_functions)
    end
  end
end
