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
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceCalled

  describe "handle_cast/2" do
    test "handles recompilation traces" do
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

    test "handles LiveComponent deletion traces" do
      transport_pid = :c.pid(0, 1, 0)
      pid = :c.pid(0, 2, 0)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:ok, %{id: "123", transport_pid: transport_pid}}
      end)

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
  end
end
