defmodule Services.TraceServiceTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.MockEtsTableServer

  @all_functions LiveDebugger.Utils.Callbacks.callbacks_functions()

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
    trace = Trace.new(1, module, :render, [], pid)

    MockEtsTableServer
    |> expect(:table!, fn ^pid -> table end)

    assert true == TraceService.insert(trace)
    assert [{trace.id, trace}] == :ets.lookup(table, trace.id)
  end

  test "get/2", %{module: module, pid: pid, table: table} do
    trace1 = Trace.new(1, module, :handle_info, [], pid)
    trace2 = Trace.new(2, module, :render, [], pid)
    :ets.insert(table, {trace1.id, trace1})
    :ets.insert(table, {trace2.id, trace2})

    MockEtsTableServer
    |> expect(:table!, 3, fn ^pid -> table end)

    assert trace1 == TraceService.get(pid, trace1.id)
    assert trace2 == TraceService.get(pid, trace2.id)
    assert nil == TraceService.get(pid, 99)
  end

  describe "existing_traces/2" do
    test "returns traces with default limit", %{module: module, pid: pid, table: table} do
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid)
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      MockEtsTableServer
      |> expect(:table!, fn ^pid -> table end)

      assert {[^trace1, ^trace2], _} =
               TraceService.existing_traces(pid, functions: @all_functions)
    end

    test "returns traces with limit and continuation", %{module: module, pid: pid, table: table} do
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid)
      trace3 = Trace.new(3, module, :handle_event, [], pid)
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      MockEtsTableServer
      |> expect(:table!, fn ^pid -> table end)

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
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid)
      trace3 = Trace.new(3, module, :handle_event, [], pid)
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      MockEtsTableServer
      |> expect(:table!, 2, fn ^pid -> table end)

      assert {[^trace1], _} = TraceService.existing_traces(pid, functions: [:handle_info])

      assert {[^trace1, ^trace2], _} =
               TraceService.existing_traces(pid, functions: [:handle_info, :render, :mount])
    end

    test "returns traces with node_id filter", %{module: module, pid: pid, table: table} do
      cid = %Phoenix.LiveComponent.CID{cid: 3}
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid, cid: cid)
      trace3 = Trace.new(3, module, :handle_event, [], pid, cid: cid)
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      MockEtsTableServer
      |> expect(:table!, 2, fn ^pid -> table end)

      assert {[^trace1], _} =
               TraceService.existing_traces(pid, node_id: pid, functions: @all_functions)

      assert {[^trace2, ^trace3], _} =
               TraceService.existing_traces(pid, node_id: cid, functions: @all_functions)
    end

    test "returns :end_of_table when no traces match", %{module: module, pid: pid, table: table} do
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid)
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      MockEtsTableServer
      |> expect(:table!, fn ^pid -> table end)

      assert :end_of_table = TraceService.existing_traces(pid, functions: [:non_existent])
    end
  end

  describe "clear_traces/2" do
    test "clears traces for LiveView or LiveComponent", %{module: module, pid: pid, table: table} do
      cid = %Phoenix.LiveComponent.CID{cid: 3}
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid, cid: cid)
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      MockEtsTableServer
      |> expect(:table!, 5, fn ^pid -> table end)

      assert {[^trace1, ^trace2], _} =
               TraceService.existing_traces(pid, functions: @all_functions)

      TraceService.clear_traces(pid, trace1.pid)

      assert {[^trace2], _} = TraceService.existing_traces(pid, functions: @all_functions)

      TraceService.clear_traces(pid, trace2.cid)

      assert :end_of_table = TraceService.existing_traces(pid, functions: @all_functions)
    end
  end
end
