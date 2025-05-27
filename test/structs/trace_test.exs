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
      timestamp = :erlang.timestamp()
      calculated_timestamp = :timer.now_diff(timestamp, {0, 0, 0})

      assert %Trace{
               id: ^id,
               module: ^module,
               function: ^function,
               args: ^args,
               pid: ^pid,
               timestamp: ^calculated_timestamp
             } = Trace.new(id, module, function, args, pid, timestamp)
    end

    test "properly gets transport_pid and socket_id from live view socket" do
      pid = :c.pid(0, 0, 1)
      transport_pid = :c.pid(0, 0, 2)
      socket_id = "socket_id"

      trace_map = %{
        id: 1,
        module: LiveDebuggerTest.TestView,
        function: :handle_event,
        args: [
          "event",
          %{"key" => "value"},
          %Phoenix.LiveView.Socket{transport_pid: transport_pid, id: socket_id}
        ],
        pid: pid,
        timestamp: :erlang.timestamp()
      }

      assert %Trace{
               transport_pid: ^transport_pid,
               socket_id: ^socket_id
             } = call_trace_new_with_map(trace_map)
    end

    test "properly gets transport_pid and socket_id from map" do
      pid = :c.pid(0, 0, 1)
      transport_pid = :c.pid(0, 0, 2)
      socket_id = "socket_id"

      trace_map = %{
        id: 1,
        module: LiveDebuggerTest.TestView,
        function: :handle_event,
        args: [
          "event",
          %{"key" => "value"},
          %{socket: %Phoenix.LiveView.Socket{transport_pid: transport_pid, id: socket_id}}
        ],
        pid: pid,
        timestamp: :erlang.timestamp()
      }

      assert %Trace{
               transport_pid: ^transport_pid,
               socket_id: ^socket_id
             } = call_trace_new_with_map(trace_map)
    end

    test "properly gets cid from myself in args" do
      pid = :c.pid(0, 0, 1)
      cid = %Phoenix.LiveComponent.CID{cid: 1}

      trace_map = %{
        id: 1,
        module: LiveDebuggerTest.TestView,
        function: :handle_event,
        args: ["event", %{"key" => "value"}, %Phoenix.LiveView.Socket{assigns: %{myself: cid}}],
        pid: pid,
        timestamp: :erlang.timestamp()
      }

      assert %Trace{cid: ^cid} = call_trace_new_with_map(trace_map)
    end

    test "properly gets cid from assigns in args" do
      pid = :c.pid(0, 0, 1)
      cid = %Phoenix.LiveComponent.CID{cid: 1}

      trace_map = %{
        id: 1,
        module: LiveDebuggerTest.TestView,
        function: :handle_event,
        args: ["event", %{"key" => "value"}, %{myself: cid}],
        pid: pid,
        timestamp: :erlang.timestamp()
      }

      assert %Trace{cid: ^cid} = call_trace_new_with_map(trace_map)
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
        timestamp: :erlang.timestamp()
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
        args: ["event", %{"key" => "value"}, %Phoenix.LiveView.Socket{assigns: %{myself: cid}}],
        pid: :c.pid(0, 0, 1),
        socket_id: "socket_id",
        timestamp: :erlang.timestamp()
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
        socket_id: "socket_id",
        timestamp: :erlang.timestamp()
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
        timestamp: :erlang.timestamp()
      }

      trace = call_trace_new_with_map(trace_map)

      refute Trace.live_component_delete?(trace)
    end
  end

  describe "arg_name/2" do
    test "returns correct args for handle_async/3" do
      trace = %{function: :handle_async, arity: 3}

      assert args_list(trace) == ["name", "async_fun_result", "socket"]
    end

    test "returns correct args for handle_call/3" do
      trace = %{function: :handle_call, arity: 3}

      assert args_list(trace) == ["message", "from", "socket"]
    end

    test "returns correct args for handle_cast/2" do
      trace = %{function: :handle_cast, arity: 2}

      assert args_list(trace) == ["message", "socket"]
    end

    test "returns correct args for handle_event/3" do
      trace = %{function: :handle_event, arity: 3}

      assert args_list(trace) == ["event", "unsigned_params", "socket"]
    end

    test "returns correct args for handle_info/2" do
      trace = %{function: :handle_info, arity: 2}

      assert args_list(trace) == ["message", "socket"]
    end

    test "returns correct args for handle_params/3" do
      trace = %{function: :handle_params, arity: 3}

      assert args_list(trace) == ["unsigned_params", "uri", "socket"]
    end

    test "returns correct args for mount/3" do
      trace = %{function: :mount, arity: 3}

      assert args_list(trace) == ["params", "session", "socket"]
    end

    test "returns correct args for mount/1" do
      trace = %{function: :mount, arity: 1}

      assert args_list(trace) == ["socket"]
    end

    test "returns correct args for render/1" do
      trace = %{function: :render, arity: 1}

      assert args_list(trace) == ["assigns"]
    end

    test "returns correct args for terminate/2" do
      trace = %{function: :terminate, arity: 2}

      assert args_list(trace) == ["reason", "socket"]
    end

    test "returns correct args for update/2" do
      trace = %{function: :update, arity: 2}

      assert args_list(trace) == ["assigns", "socket"]
    end

    test "returns correct args for update_many/1" do
      trace = %{function: :update_many, arity: 1}

      assert args_list(trace) == ["list"]
    end
  end

  test "callback_name/1 returns callback with arity" do
    trace_map = %{
      id: 1,
      module: LiveDebuggerTest.TestView,
      function: :handle_event,
      args: ["event", %{"key" => "value"}, %{}],
      pid: :c.pid(0, 0, 1),
      timestamp: :erlang.timestamp()
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
           pid: pid,
           timestamp: timestamp
         } = map
       ) do
    opts =
      map
      |> Map.drop([:id, :module, :function, :args, :pid, :timestamp])
      |> Enum.into([])

    Trace.new(id, module, function, args, pid, timestamp, opts)
  end

  defp args_list(trace) do
    for index <- 0..(trace.arity - 1) do
      Trace.arg_name(trace, index)
    end
  end
end
