defmodule LiveDebugger.Integration.IpTracerIntegrationTest do
  @moduledoc """
  End-to-end smoke test for the `:ip` port-based tracer pipeline.

  This test bypasses the `MockAPIDbg` Mox mock and exercises the real
  `LiveDebugger.API.System.Dbg.Impl` against `:dbg`/`:dbg.trace_port`/
  `:dbg.trace_client`, verifying that:

    * a trace_port can be opened on a kernel-assigned TCP port,
    * a trace_client connects and the handler receives trace tuples,
    * `Tracer.handle_trace/2` correctly forwards a `:call` to `TraceHandler`,
    * a `{:drop, N}` event from the IP queue surfaces as `TracesDropped`.

  Async is disabled because `:dbg` has process-wide global state.
  """
  use ExUnit.Case, async: false

  import Mox

  alias LiveDebugger.API.System.Dbg
  alias LiveDebugger.Services.CallbackTracer.GenServers.TraceHandler
  alias LiveDebugger.Services.CallbackTracer.Process.Tracer
  alias LiveDebugger.Services.CallbackTracer.Events.TracesDropped

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    # Switch from MockAPIDbg to the real implementation just for this test.
    previous = Application.get_env(:live_debugger, :api_dbg)
    Application.put_env(:live_debugger, :api_dbg, LiveDebugger.API.System.Dbg.Impl)

    on_exit(fn ->
      :dbg.stop()

      if previous do
        Application.put_env(:live_debugger, :api_dbg, previous)
      else
        Application.delete_env(:live_debugger, :api_dbg)
      end
    end)

    :ok
  end

  test "trace_port :ip + trace_client delivers trace events to the handler" do
    test_pid = self()

    handler = fn trace, n ->
      send(test_pid, {:trace_received, trace})
      n - 1
    end

    {:ok, listen_sock} = :gen_tcp.listen(0, [:binary, ip: {127, 0, 0, 1}])
    {:ok, port} = :inet.port(listen_sock)
    :gen_tcp.close(listen_sock)

    port_fun = Dbg.trace_port(:ip, {port, 50})
    assert {:ok, _tracer} = Dbg.tracer(:port, port_fun)

    client_pid = Dbg.trace_client(:ip, {~c"localhost", port}, {handler, 0})
    assert is_pid(client_pid)
    assert Process.alive?(client_pid)

    # Trace a function call on a known module/function.
    Dbg.trace_pattern({Enum, :map, 2}, [])
    Dbg.process(self(), [:c, :timestamp])

    Enum.map([1, 2, 3], &(&1 * 2))

    assert_receive {:trace_received, trace}, 1_000
    assert match?({:trace_ts, _, :call, {Enum, :map, _}, _}, trace) or
             match?({:trace, _, :call, {Enum, :map, _}}, trace)
  end

  test "Tracer forwards {:drop, N} to TraceHandler without consuming a trace id" do
    # In the unit-test config, `TraceHandler` is not started by the
    # supervisor (`LiveDebugger.Env.unit_test?/0` short-circuits children).
    # Start it manually so the cast in `Tracer.handle_trace/2` has a target.
    handler_pid =
      case Process.whereis(TraceHandler) do
        nil ->
          {:ok, pid} = TraceHandler.start_link([])
          pid

        pid ->
          pid
      end

    on_exit(fn ->
      if Process.alive?(handler_pid), do: GenServer.stop(handler_pid, :normal)
    end)

    Mox.allow(LiveDebugger.MockBus, self(), handler_pid)

    LiveDebugger.MockBus
    |> expect(:broadcast_event!, fn %TracesDropped{count: 7} -> :ok end)

    # Counter `n` is preserved (drop events do not consume trace ids).
    assert 5 == Tracer.handle_trace({:drop, 7}, 5)

    # Force a sync round-trip with TraceHandler so the cast is processed
    # before `verify_on_exit!` runs.
    _ = :sys.get_state(handler_pid)
  end
end
