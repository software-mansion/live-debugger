defmodule LiveDebugger.Services.CallbackTracer.Actions.TraceTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Services.CallbackTracer.Actions.Trace
  alias LiveDebugger.Structs.Trace.FunctionTrace, as: TraceStruct
  alias LiveDebugger.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebugger.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebugger.Services.CallbackTracer.Events.TraceErrored
  alias LiveDebugger.MockAPITracesStorage
  alias LiveDebugger.MockBus
  import Mox

  setup :verify_on_exit!

  describe "create_trace/6" do
    test "creates a trace successfully with valid parameters" do
      n = 1
      module = TestModule
      fun = :test_function
      args = [%{transport_pid: :c.pid(0, 1, 0)}]
      pid = :c.pid(0, 2, 0)
      timestamp = {1000, 100, 1000}

      result = Trace.create_trace(n, module, fun, args, pid, timestamp)

      assert {:ok, %TraceStruct{} = trace} = result
      assert trace.id == n
      assert trace.module == module
      assert trace.function == fun
      assert trace.args == args
      assert trace.pid == pid
      assert trace.arity == 1
      assert trace.type == :call
      assert trace.transport_pid == :c.pid(0, 1, 0)
    end

    test "returns error when transport_pid is nil" do
      n = 1
      module = TestModule
      fun = :test_function
      args = []
      pid = self()
      timestamp = {1000, 100, 1000}

      result = Trace.create_trace(n, module, fun, args, pid, timestamp)

      assert {:error, "Transport PID is nil"} = result
    end
  end

  describe "update_trace/2" do
    test "updates trace with new parameters" do
      original_trace = %TraceStruct{
        id: 1,
        module: TestModule,
        function: :test_function,
        args: [1, 2, 3],
        pid: self(),
        execution_time: nil,
        type: :call
      }

      update_params = %{execution_time: 100, type: :return_from}

      result = Trace.update_trace(original_trace, update_params)

      assert {:ok, %TraceStruct{} = updated_trace} = result
      assert updated_trace.id == 1
      assert updated_trace.module == TestModule
      assert updated_trace.function == :test_function
      assert updated_trace.execution_time == 100
      assert updated_trace.type == :return_from
    end
  end

  describe "persist_trace/2" do
    test "persists trace with provided table reference" do
      table_ref = make_ref()

      MockAPITracesStorage
      |> expect(:insert!, fn ^table_ref, _ -> true end)

      trace = %TraceStruct{
        id: 1,
        module: TestModule,
        function: :test_function,
        args: [1, 2, 3],
        pid: self(),
        type: :call
      }

      assert {:ok, ^table_ref} = Trace.persist_trace(trace, table_ref)
    end
  end

  describe "publish_trace/2" do
    test "creates correct TraceCalled event for call type" do
      pid = :c.pid(0, 1, 0)
      table_ref = make_ref()

      MockBus
      |> expect(:broadcast_trace!, fn arg1, ^pid ->
        assert %TraceCalled{
                 trace_id: 1,
                 ets_ref: ^table_ref,
                 module: TestModule,
                 function: :test_function,
                 pid: ^pid,
                 cid: nil
               } = arg1

        :ok
      end)

      trace = %TraceStruct{
        id: 1,
        module: TestModule,
        function: :test_function,
        args: [1, 2, 3],
        pid: pid,
        type: :call,
        cid: nil
      }

      result = Trace.publish_trace(trace, table_ref)

      assert :ok = result
    end

    test "creates correct TraceReturned event for return_from type" do
      pid = :c.pid(0, 1, 0)
      table_ref = make_ref()

      MockBus
      |> expect(:broadcast_trace!, fn arg1, ^pid ->
        assert %TraceReturned{
                 trace_id: 2,
                 ets_ref: ^table_ref,
                 module: TestModule,
                 function: :test_function,
                 pid: ^pid,
                 cid: nil
               } = arg1

        :ok
      end)

      trace = %TraceStruct{
        id: 2,
        module: TestModule,
        function: :test_function,
        args: [1, 2, 3],
        pid: pid,
        type: :return_from,
        cid: nil
      }

      result = Trace.publish_trace(trace, table_ref)

      assert :ok = result
    end

    test "creates correct TraceErrored event for exception_from type" do
      pid = :c.pid(0, 1, 0)
      table_ref = make_ref()

      MockBus
      |> expect(:broadcast_trace!, fn arg1, ^pid ->
        assert %TraceErrored{
                 trace_id: 3,
                 ets_ref: ^table_ref,
                 module: TestModule,
                 function: :test_function,
                 pid: ^pid,
                 cid: nil
               } = arg1

        :ok
      end)

      trace = %TraceStruct{
        id: 3,
        module: TestModule,
        function: :test_function,
        args: [1, 2, 3],
        pid: pid,
        type: :exception_from,
        cid: nil
      }

      result = Trace.publish_trace(trace, table_ref)

      assert :ok = result
    end

    test "handles trace with CID" do
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      pid = :c.pid(0, 1, 0)
      table_ref = make_ref()

      MockBus
      |> expect(:broadcast_trace!, fn arg1, ^pid ->
        assert %TraceCalled{
                 trace_id: 4,
                 ets_ref: ^table_ref,
                 module: TestModule,
                 function: :test_function,
                 pid: ^pid,
                 cid: ^cid
               } = arg1

        :ok
      end)

      trace = %TraceStruct{
        id: 4,
        module: TestModule,
        function: :test_function,
        args: [1, 2, 3],
        pid: pid,
        type: :call,
        cid: cid
      }

      result = Trace.publish_trace(trace, table_ref)

      assert :ok = result
    end
  end
end
