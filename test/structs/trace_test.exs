defmodule LiveDebugger.Structs.TraceTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Structs.Trace

  describe "new/6" do
    test "creates a new Trace struct with the given parameters" do
      id = 1
      module = LiveDebuggerTest.TestView
      function = :handle_event
      args = ["event", %{"key" => "value"}, %{}]
      pid = :c.pid(0, 0, 1)

      assert %Trace{
               id: ^id,
               module: ^module,
               function: ^function,
               args: ^args,
               pid: ^pid
             } = Trace.new(id, module, function, args, pid)
    end

    test "adds timestamp when created" do
      trace_map = %{
        id: 1,
        module: LiveDebuggerTest.TestView,
        function: :handle_event,
        args: ["event", %{"key" => "value"}, %{}],
        pid: :c.pid(0, 0, 1),
        socket_id: "socket_id"
      }

      trace = call_trace_new_with_map(trace_map)

      timestamp = :os.system_time(:microsecond)

      assert is_integer(trace.timestamp)
      assert abs(trace.timestamp - timestamp) < 200
    end
  end

  describe "node_id/1" do
    test "returns the pid if cid is nil" do
      pid = :c.pid(0, 0, 1)

      trace_map = %{
        id: 1,
        module: LiveDebuggerTest.TestView,
        function: :handle_event,
        args: ["event", %{"key" => "value"}, %{}],
        pid: pid,
        cid: nil
      }

      trace = call_trace_new_with_map(trace_map)

      assert Trace.node_id(trace) == pid
    end

    test "returns the cid if it is not nil" do
      cid = %Phoenix.LiveComponent.CID{cid: 1}

      trace_map = %{
        id: 1,
        module: LiveDebuggerTest.TestView,
        function: :handle_event,
        args: ["event", %{"key" => "value"}, %{}],
        pid: :c.pid(0, 0, 1),
        cid: cid,
        socket_id: "socket_id"
      }

      trace = call_trace_new_with_map(trace_map)

      assert Trace.node_id(trace) == cid
    end
  end

  describe "live_component_delete?/1" do
    test "returns true if the trace is a delete live component trace" do
      cid = %Phoenix.LiveComponent.CID{cid: 1}

      trace_map = %{
        id: 1,
        module: Phoenix.LiveView.Diff,
        function: :delete_component,
        args: [cid, {nil, nil, []}],
        pid: :c.pid(0, 0, 1),
        cid: cid,
        socket_id: "socket_id"
      }

      trace = call_trace_new_with_map(trace_map)

      assert Trace.live_component_delete?(trace)
    end

    test "returns false if the trace is not a delete live component trace" do
      trace_map = %{
        id: 1,
        module: LiveDebuggerTest.TestView,
        function: :handle_event,
        args: ["event", %{"key" => "value"}, %{}],
        pid: :c.pid(0, 0, 1),
        cid: nil
      }

      trace = call_trace_new_with_map(trace_map)

      refute Trace.live_component_delete?(trace)
    end
  end

  test "callback_name/1 returns callback with arity" do
    trace_map = %{
      id: 1,
      module: LiveDebuggerTest.TestView,
      function: :handle_event,
      args: ["event", %{"key" => "value"}, %{}],
      pid: :c.pid(0, 0, 1),
      cid: nil
    }

    trace = call_trace_new_with_map(trace_map)

    assert Trace.callback_name(trace) == "handle_event/3"
  end

  defp call_trace_new_with_map(
         %{
           id: id,
           module: module,
           function: function,
           args: args,
           pid: pid
         } = map
       ) do
    opts =
      map
      |> Map.drop([:id, :module, :function, :args, :pid])
      |> Enum.into([])

    Trace.new(id, module, function, args, pid, opts)
  end
end
