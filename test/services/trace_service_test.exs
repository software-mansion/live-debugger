defmodule Services.TraceServiceTest do
  use ExUnit.Case, async: false

  import Mox

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.GenServers.CallbackTracingServer

  setup_all do
    LiveDebugger.MockModuleService
    |> stub(:all, fn -> [] end)

    allow(LiveDebugger.MockModuleService, self(), fn ->
      GenServer.whereis(CallbackTracingServer)
    end)

    start_supervised(CallbackTracingServer)

    %{module: CoolApp.LiveViews.UserDashboard}
  end

  setup context do
    pid = spawn(fn -> Process.sleep(:infinity) end)

    on_exit(fn -> Process.exit(pid, :kill) end)

    Map.put(context, :pid, pid)
  end

  test "insert/1", %{module: module, pid: pid} do
    trace = Trace.new(1, module, :render, [], pid)

    assert true == TraceService.insert(trace)
  end

  test "get/2", %{module: module, pid: pid} do
    trace1 = Trace.new(1, module, :handle_info, [], pid)
    trace2 = Trace.new(2, module, :render, [], pid)

    TraceService.insert(trace1)
    TraceService.insert(trace2)

    assert trace1 == TraceService.get(pid, trace1.id)
    assert trace2 == TraceService.get(pid, trace2.id)
    assert nil == TraceService.get(pid, 99)
  end

  describe "existing_traces/2" do
    test "returns traces with default limit", %{module: module, pid: pid} do
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid)

      TraceService.insert(trace1)
      TraceService.insert(trace2)

      assert {[^trace1, ^trace2], _} = TraceService.existing_traces(pid)
    end

    test "returns traces with limit and continuation", %{module: module, pid: pid} do
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid)
      trace3 = Trace.new(3, module, :handle_event, [], pid)

      TraceService.insert(trace1)
      TraceService.insert(trace2)
      TraceService.insert(trace3)

      {traces1, cont} = TraceService.existing_traces(pid, limit: 2)
      {traces2, cont} = TraceService.existing_traces(pid, cont: cont)

      assert [trace1, trace2] == traces1
      assert [trace3] == traces2
      assert cont == :end_of_table
      assert :end_of_table == TraceService.existing_traces(pid, cont: :end_of_table)
    end

    test "raise ArgumentError when limit is less than 1", %{pid: pid} do
      assert_raise ArgumentError, fn -> TraceService.existing_traces(pid, limit: 0) end
      assert_raise ArgumentError, fn -> TraceService.existing_traces(pid, limit: -23) end
    end

    test "returns traces with functions filter", %{module: module, pid: pid} do
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid)
      trace3 = Trace.new(3, module, :handle_event, [], pid)

      TraceService.insert(trace1)
      TraceService.insert(trace2)
      TraceService.insert(trace3)

      assert {[^trace1], _} = TraceService.existing_traces(pid, functions: [:handle_info])

      assert {[^trace1, ^trace2], _} =
               TraceService.existing_traces(pid, functions: [:handle_info, :render, :mount])
    end

    test "returns traces with node_id filter", %{module: module, pid: pid} do
      cid = %Phoenix.LiveComponent.CID{cid: 3}
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid, cid: cid)
      trace3 = Trace.new(3, module, :handle_event, [], pid, cid: cid)

      TraceService.insert(trace1)
      TraceService.insert(trace2)
      TraceService.insert(trace3)

      assert {[^trace1], _} = TraceService.existing_traces(pid, node_id: pid)
      assert {[^trace2, ^trace3], _} = TraceService.existing_traces(pid, node_id: cid)
    end

    test "returns :end_of_table when no traces match", %{module: module, pid: pid} do
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid)

      TraceService.insert(trace1)
      TraceService.insert(trace2)

      assert :end_of_table = TraceService.existing_traces(pid, functions: [:non_existent])
    end
  end

  describe "clear_traces/2" do
    test "clears traces for LiveView or LiveComponent", %{module: module, pid: pid} do
      cid = %Phoenix.LiveComponent.CID{cid: 3}
      trace1 = Trace.new(1, module, :handle_info, [], pid)
      trace2 = Trace.new(2, module, :render, [], pid, cid: cid)

      TraceService.insert(trace1)
      TraceService.insert(trace2)

      assert {[^trace1, ^trace2], _} = TraceService.existing_traces(pid)

      TraceService.clear_traces(pid, trace1.pid)

      assert {[^trace2], _} = TraceService.existing_traces(pid)

      TraceService.clear_traces(pid, trace2.cid)

      assert :end_of_table = TraceService.existing_traces(pid)
    end
  end
end
