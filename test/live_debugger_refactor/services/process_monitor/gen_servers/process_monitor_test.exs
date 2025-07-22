defmodule LiveDebuggerRefactor.Services.ProcessMonitor.GenServers.ProcessMonitorTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Services.ProcessMonitor.GenServers.ProcessMonitor
  alias LiveDebuggerRefactor.MockAPILiveViewDebug

  alias LiveDebuggerRefactor.MockBus
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveComponentDeleted
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveComponentCreated
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned

  setup :verify_on_exit!

  test "init/1" do
    expect(MockBus, :receive_traces!, fn -> :ok end)

    assert {:ok, %{}} = ProcessMonitor.init([])
  end

  describe "handle_info/2" do
    test "with TraceReturned for render with known cid" do
      pid = self()
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      state = %{pid => MapSet.new([cid])}

      event = %TraceReturned{
        trace_id: -1,
        module: TestLV.Component,
        function: :render,
        cid: cid,
        pid: pid,
        ets_ref: nil
      }

      MockBus
      |> deny(:broadcast_event!, 2)

      assert {:noreply, ^state} = ProcessMonitor.handle_info(event, state)
    end

    test "with TraceReturned for render with unknown cid" do
      pid = self()
      cid1 = %Phoenix.LiveComponent.CID{cid: 1}
      cid2 = %Phoenix.LiveComponent.CID{cid: 2}
      state = %{pid => MapSet.new([cid1])}

      event = %TraceReturned{
        trace_id: -1,
        module: TestLV.Component,
        function: :render,
        cid: cid2,
        pid: pid,
        ets_ref: nil
      }

      MockBus
      |> expect(:broadcast_event!, fn %LiveComponentCreated{cid: ^cid2, pid: ^pid}, ^pid ->
        :ok
      end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)
      assert new_state == %{pid => MapSet.new([cid1, cid2])}
    end

    test "with TraceReturned for render with unknown pid" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      cid1 = %Phoenix.LiveComponent.CID{cid: 1}
      state = %{pid1 => MapSet.new([cid1])}

      event = %TraceReturned{
        trace_id: -1,
        module: TestLV.Component,
        function: :render,
        cid: cid1,
        pid: pid2,
        ets_ref: nil
      }

      MockBus
      |> expect(:broadcast_event!, fn %LiveViewBorn{pid: ^pid2} -> :ok end)

      MockAPILiveViewDebug
      |> expect(:live_components, fn ^pid2 -> {:ok, [%{cid: 1}, %{cid: 2}]} end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)

      assert new_state == %{
               pid1 => MapSet.new([cid1]),
               pid2 =>
                 MapSet.new([
                   %Phoenix.LiveComponent.CID{cid: 1},
                   %Phoenix.LiveComponent.CID{cid: 2}
                 ])
             }
    end

    test "with TraceReturned for render with nil cid and known pid" do
      pid = self()
      state = %{pid => MapSet.new()}

      event = %TraceReturned{
        trace_id: -1,
        module: TestLV,
        function: :render,
        cid: nil,
        pid: pid,
        ets_ref: nil
      }

      MockBus
      |> deny(:broadcast_event!, 2)

      assert {:noreply, ^state} = ProcessMonitor.handle_info(event, state)
    end

    test "with TraceReturned for render with nil cid and unknown pid" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      state = %{pid1 => MapSet.new()}

      event = %TraceReturned{
        trace_id: -1,
        module: TestLV,
        function: :render,
        cid: nil,
        pid: pid2,
        ets_ref: nil
      }

      MockBus
      |> expect(:broadcast_event!, fn %LiveViewBorn{pid: ^pid2} -> :ok end)

      MockAPILiveViewDebug
      |> expect(:live_components, fn ^pid2 -> {:ok, [%{cid: 1}, %{cid: 2}]} end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)

      assert new_state == %{
               pid1 => MapSet.new(),
               pid2 =>
                 MapSet.new([
                   %Phoenix.LiveComponent.CID{cid: 1},
                   %Phoenix.LiveComponent.CID{cid: 2}
                 ])
             }
    end

    test "with TraceCalled for delete_component with known cid" do
      pid = self()
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      state = %{pid => MapSet.new([cid])}

      event = %TraceCalled{
        trace_id: -1,
        module: Phoenix.LiveView.Diff,
        function: :delete_component,
        cid: cid,
        pid: pid,
        ets_ref: nil
      }

      MockBus
      |> expect(:broadcast_event!, fn %LiveComponentDeleted{cid: ^cid, pid: ^pid}, ^pid -> :ok end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)
      assert new_state == %{pid => MapSet.new()}
    end

    test "with TraceCalled for delete_component with unknown cid" do
      pid = self()
      cid1 = %Phoenix.LiveComponent.CID{cid: 1}
      cid2 = %Phoenix.LiveComponent.CID{cid: 2}
      state = %{pid => MapSet.new([cid1])}

      event = %TraceCalled{
        trace_id: -1,
        module: Phoenix.LiveView.Diff,
        function: :delete_component,
        cid: cid2,
        pid: pid,
        ets_ref: nil
      }

      MockBus
      |> deny(:broadcast_event!, 2)

      assert {:noreply, ^state} = ProcessMonitor.handle_info(event, state)
    end

    test "with TraceCalled for delete_component with unknown pid" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      state = %{pid1 => MapSet.new([cid])}

      event = %TraceCalled{
        trace_id: -1,
        module: Phoenix.LiveView.Diff,
        function: :delete_component,
        cid: cid,
        pid: pid2,
        ets_ref: nil
      }

      MockBus
      |> deny(:broadcast_event!, 2)

      assert {:noreply, ^state} = ProcessMonitor.handle_info(event, state)
    end

    test "with DOWN message for known pid" do
      pid = self()
      state = %{pid => MapSet.new()}

      event = {:DOWN, 1, :process, pid, :normal}

      MockBus
      |> expect(:broadcast_event!, fn %LiveViewDied{pid: ^pid} -> :ok end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)
      assert new_state == %{}
    end

    test "with DOWN message for unknown pid" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      state = %{pid1 => MapSet.new()}

      event = {:DOWN, 1, :process, pid2, :normal}

      MockBus
      |> deny(:broadcast_event!, 2)

      assert {:noreply, ^state} = ProcessMonitor.handle_info(event, state)
    end
  end
end
