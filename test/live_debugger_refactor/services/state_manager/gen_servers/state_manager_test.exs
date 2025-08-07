defmodule LiveDebuggerRefactor.Services.StateManager.GenServers.StateManagerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.MockBus
  alias LiveDebuggerRefactor.Services.StateManager.Events.StateChanged
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveComponentDeleted

  alias LiveDebuggerRefactor.Services.StateManager.GenServers.StateManager
  alias LiveDebuggerRefactor.MockAPILiveViewDebug
  alias LiveDebuggerRefactor.MockAPIStatesStorage
  alias LiveDebuggerRefactor.Fakes

  setup :verify_on_exit!

  describe "init/1" do
    test "properly initializes StateManager" do
      MockBus
      |> expect(:receive_traces!, fn -> :ok end)
      |> expect(:receive_events!, fn -> :ok end)

      assert {:ok, []} = StateManager.init([])
    end
  end

  describe "handle_info/2" do
    setup do
      pid = :c.pid(0, 123, 0)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:ok, Fakes.socket()}
      end)
      |> expect(:live_components, fn ^pid ->
        {:ok, Fakes.live_components()}
      end)

      MockAPIStatesStorage
      |> expect(:save!, fn _ -> true end)

      {:ok, pid: pid}
    end

    test "handles TraceReturned event", %{pid: pid} do
      trace_event = %TraceReturned{
        trace_id: -1,
        function: :render,
        arity: 1,
        module: LiveDebuggerTest.DummyLiveView,
        ets_ref: nil,
        cid: nil,
        pid: pid,
        transport_pid: nil
      }

      MockBus |> expect(:broadcast_state!, fn %StateChanged{pid: ^pid}, ^pid -> :ok end)

      assert {:noreply, []} = StateManager.handle_info(trace_event, [])
    end

    test "handles LiveComponentDeleted event", %{pid: pid} do
      delete_event = %LiveComponentDeleted{
        pid: pid,
        cid: %Phoenix.LiveComponent.CID{cid: 1}
      }

      MockBus |> expect(:broadcast_state!, fn %StateChanged{pid: ^pid}, ^pid -> :ok end)

      assert {:noreply, []} = StateManager.handle_info(delete_event, [])
    end
  end

  test "handle_info/2 ignores other events" do
    assert {:noreply, []} = StateManager.handle_info(:some_other_event, [])
  end
end
