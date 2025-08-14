defmodule LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TraceHandlerTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!
  setup :set_mox_from_context

  alias LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TraceHandler
  alias LiveDebuggerRefactor.MockAPIDbg
  alias LiveDebuggerRefactor.MockAPIModule
  alias LiveDebuggerRefactor.MockAPILiveViewDebug
  alias LiveDebuggerRefactor.MockBus
  alias LiveDebuggerRefactor.MockAPITracesStorage
  alias LiveDebuggerRefactor.MockAPIStatesStorage
  alias LiveDebugger.Fakes
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceErrored
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.StateChanged

  describe "handle_cast/2" do
    test "handles proper recompilation traces" do
      pid = :c.pid(0, 1, 0)

      MockAPIDbg
      |> expect(:trace_pattern, 19, fn _, _ -> :ok end)

      MockAPIModule
      |> expect(:all, fn -> [{~c"Debugged.TestModule", ~c"delete_component", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      trace =
        {:new_trace,
         {:trace_ts, pid, :return_from, {Mix.Tasks.Compile.Elixir, :run, 1}, {:ok, []},
          {1753, 174_270, 660_820}}, -1}

      assert TraceHandler.handle_cast(trace, nil) == {:noreply, nil}

      Process.sleep(400)
    end

    test "handles incorrect recompilation traces" do
      pid = :c.pid(0, 1, 0)

      trace1 =
        {:new_trace,
         {:trace_ts, pid, :call, {Mix.Tasks.Compile.Elixir, :run, 1}, {1753, 174_270, 660_820}},
         -1}

      trace2 =
        {:new_trace,
         {:trace_ts, pid, :return_from, {Mix.Tasks.Compile.Elixir, :run, 1}, {:error, []},
          {1753, 174_270, 660_820}}, -1}

      assert TraceHandler.handle_cast(trace1, %{}) == {:noreply, %{}}
      assert TraceHandler.handle_cast(trace2, %{}) == {:noreply, %{}}
    end

    test "handles LiveComponent deletion traces" do
      transport_pid = :c.pid(0, 1, 0)
      pid = :c.pid(0, 2, 0)
      socket = %{id: "123", transport_pid: transport_pid}

      # create delete trace
      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, socket} end)

      # save state
      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, socket} end)
      |> expect(:live_components, fn ^pid -> {:ok, []} end)

      MockAPIStatesStorage
      |> expect(:save!, fn _ -> true end)

      # broadcast state
      MockBus
      |> expect(:broadcast_state!, fn %StateChanged{pid: ^pid}, ^pid ->
        :ok
      end)

      # broadcast trace
      MockBus
      |> expect(:broadcast_trace!, fn arg1, ^pid ->
        assert %TraceCalled{
                 trace_id: -1,
                 ets_ref: nil,
                 module: Phoenix.LiveView.Diff,
                 function: :delete_component,
                 pid: ^pid,
                 cid: %Phoenix.LiveComponent.CID{cid: 15}
               } = arg1

        :ok
      end)

      trace =
        {:new_trace,
         {:trace_ts, pid, :call, {Phoenix.LiveView.Diff, :delete_component, [15, %{}]},
          {1753, 176_335, 405_037}}, -1}

      assert TraceHandler.handle_cast(trace, nil) == {:noreply, nil}

      Process.sleep(400)
    end

    test "handles callback call traces successfully" do
      pid = :c.pid(0, 1, 0)
      module = TestModule
      fun = :render
      args = [%{transport_pid: pid}]
      ts = {1753, 174_270, 660_820}
      n = 1
      ref = make_ref()

      MockAPITracesStorage
      |> expect(:get_table, fn ^pid -> ref end)
      |> expect(:insert!, fn ^ref, _trace -> true end)

      MockBus
      |> expect(:broadcast_trace!, fn arg1, ^pid ->
        assert %TraceCalled{
                 trace_id: ^n,
                 ets_ref: ^ref,
                 module: ^module,
                 function: ^fun,
                 pid: ^pid,
                 cid: nil
               } = arg1

        :ok
      end)

      trace = {:new_trace, {:trace_ts, pid, :call, {module, fun, args}, ts}, n}

      result = TraceHandler.handle_cast(trace, %{})
      assert {:noreply, state} = result
      assert Map.has_key?(state, {pid, module, fun})
      assert {^ref, _, ^ts} = Map.get(state, {pid, module, fun})
    end

    test "handles callback call traces with nil transport_pid" do
      pid = :c.pid(0, 1, 0)
      module = TestModule
      fun = :render
      args = []
      ts = {1753, 174_270, 660_820}
      n = 1

      trace = {:new_trace, {:trace_ts, pid, :call, {module, fun, args}, ts}, n}

      result = TraceHandler.handle_cast(trace, %{})
      assert {:noreply, %{}} = result
    end

    test "handles callback return_from traces successfully" do
      pid = :c.pid(0, 1, 0)
      module = TestModule
      fun = :render
      call_ts = {1753, 174_270, 660_820}
      return_ts = {1753, 174_270, 760_820}
      ref = make_ref()

      trace = %LiveDebuggerRefactor.Structs.Trace{
        id: 1,
        module: module,
        function: fun,
        pid: pid,
        type: :call
      }

      state = %{{pid, module, fun} => {ref, trace, call_ts}}

      MockAPITracesStorage
      |> expect(:insert!, fn ^ref, updated_trace ->
        assert %LiveDebuggerRefactor.Structs.Trace{
                 id: 1,
                 module: ^module,
                 function: ^fun,
                 pid: ^pid,
                 type: :return_from
               } = updated_trace

        true
      end)

      # save state
      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, Fakes.socket()} end)
      |> expect(:live_components, fn ^pid -> {:ok, []} end)

      MockAPIStatesStorage
      |> expect(:save!, fn _ -> true end)

      # broadcast state
      MockBus
      |> expect(:broadcast_state!, fn %StateChanged{pid: ^pid}, ^pid ->
        :ok
      end)

      MockBus
      |> expect(:broadcast_trace!, fn arg1, ^pid ->
        assert %TraceReturned{
                 trace_id: 1,
                 ets_ref: ^ref,
                 module: ^module,
                 function: ^fun,
                 pid: ^pid,
                 cid: nil
               } = arg1

        :ok
      end)

      trace_msg =
        {:new_trace, {:trace_ts, pid, :return_from, {module, fun, 1}, :ok, return_ts}, 1}

      result = TraceHandler.handle_cast(trace_msg, state)
      assert {:noreply, new_state} = result
      assert map_size(new_state) == 0
    end

    test "handles callback exception_from traces successfully" do
      pid = :c.pid(0, 1, 0)
      module = TestModule
      fun = :render
      call_ts = {1753, 174_270, 660_820}
      return_ts = {1753, 174_270, 760_820}
      ref = make_ref()

      trace = %LiveDebuggerRefactor.Structs.Trace{
        id: 1,
        module: module,
        function: fun,
        pid: pid,
        type: :call
      }

      state = %{{pid, module, fun} => {ref, trace, call_ts}}

      MockAPITracesStorage
      |> expect(:insert!, fn ^ref, updated_trace ->
        assert %LiveDebuggerRefactor.Structs.Trace{
                 id: 1,
                 module: ^module,
                 function: ^fun,
                 pid: ^pid,
                 type: :exception_from
               } = updated_trace

        true
      end)

      MockBus
      |> expect(:broadcast_trace!, fn arg1, ^pid ->
        assert %TraceErrored{
                 trace_id: 1,
                 ets_ref: ^ref,
                 module: ^module,
                 function: ^fun,
                 pid: ^pid,
                 cid: nil
               } = arg1

        :ok
      end)

      trace_msg =
        {:new_trace, {:trace_ts, pid, :exception_from, {module, fun, 1}, :error, return_ts}, 1}

      result = TraceHandler.handle_cast(trace_msg, state)
      assert {:noreply, new_state} = result
      assert map_size(new_state) == 0
    end

    test "handles callback return traces with missing trace record" do
      pid = :c.pid(0, 1, 0)
      module = TestModule
      fun = :render
      return_ts = {1753, 174_270, 760_820}
      state = %{}

      trace_msg =
        {:new_trace, {:trace_ts, pid, :return_from, {module, fun, 1}, :ok, return_ts}, 1}

      result = TraceHandler.handle_cast(trace_msg, state)
      assert {:noreply, %{}} = result
    end

    test "ignores non-allowed callback functions" do
      pid = :c.pid(0, 1, 0)
      module = TestModule
      fun = :non_allowed_function
      args = [1, 2, 3]
      ts = {1753, 174_270, 660_820}
      n = 1

      trace = {:new_trace, {:trace_ts, pid, :call, {module, fun, args}, ts}, n}

      result = TraceHandler.handle_cast(trace, %{})
      assert {:noreply, %{}} = result
    end

    test "handles malformed traces gracefully" do
      malformed_trace = {:new_trace, :malformed_data, 1}

      result = TraceHandler.handle_cast(malformed_trace, %{})
      assert {:noreply, %{}} = result
    end
  end
end
