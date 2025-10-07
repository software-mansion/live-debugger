defmodule LiveDebugger.Services.ProcessMonitor.GenServers.ProcessMonitorTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.App.Events.DebuggerMounted
  alias LiveDebugger.Services.ProcessMonitor.GenServers.ProcessMonitor
  alias LiveDebugger.MockAPILiveViewDebug

  alias LiveDebugger.MockBus
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentDeleted
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentCreated
  alias LiveDebugger.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebugger.Services.ProcessMonitor.Events.DebuggerTerminated

  setup :verify_on_exit!

  test "init/1" do
    MockBus
    |> expect(:receive_traces!, fn -> :ok end)
    |> expect(:receive_events!, fn -> :ok end)

    assert {:ok, %{debugged: %{}, debugger: MapSet.new()}} == ProcessMonitor.init([])
  end

  describe "handle_info/2" do
    test "with TraceCalled for render with known cid" do
      pid = self()
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      state = %{debugged: %{pid => MapSet.new([cid])}}

      event = %TraceCalled{
        trace_id: -1,
        module: TestLV.Component,
        function: :render,
        arity: 1,
        cid: cid,
        pid: pid,
        ets_ref: nil,
        transport_pid: nil
      }

      MockBus
      |> deny(:broadcast_event!, 2)

      assert {:noreply, ^state} = ProcessMonitor.handle_info(event, state)
    end

    test "with TraceCalled for render with unknown cid" do
      pid = self()
      cid1 = %Phoenix.LiveComponent.CID{cid: 1}
      cid2 = %Phoenix.LiveComponent.CID{cid: 2}
      state = %{debugged: %{pid => MapSet.new([cid1])}}

      event = %TraceCalled{
        trace_id: -1,
        module: TestLV.Component,
        function: :render,
        arity: 1,
        cid: cid2,
        pid: pid,
        ets_ref: nil,
        transport_pid: nil
      }

      MockBus
      |> expect(:broadcast_event!, fn %LiveComponentCreated{cid: ^cid2, pid: ^pid}, ^pid ->
        :ok
      end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)
      assert new_state == %{debugged: %{pid => MapSet.new([cid1, cid2])}}
    end

    test "with TraceCalled for render with unknown pid" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      cid1 = %Phoenix.LiveComponent.CID{cid: 1}
      state = %{debugged: %{pid1 => MapSet.new([cid1])}}

      event = %TraceCalled{
        trace_id: -1,
        module: TestLV.Component,
        function: :render,
        arity: 1,
        cid: cid1,
        pid: pid2,
        ets_ref: nil,
        transport_pid: nil
      }

      MockBus
      |> expect(:broadcast_event!, fn %LiveViewBorn{pid: ^pid2} -> :ok end)

      MockAPILiveViewDebug
      |> expect(:live_components, fn ^pid2 -> {:ok, [%{cid: 1}, %{cid: 2}]} end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)

      assert new_state == %{
               debugged: %{
                 pid1 => MapSet.new([cid1]),
                 pid2 =>
                   MapSet.new([
                     %Phoenix.LiveComponent.CID{cid: 1},
                     %Phoenix.LiveComponent.CID{cid: 2}
                   ])
               }
             }
    end

    test "with TraceCalled for render with nil cid and known pid" do
      pid = self()
      state = %{debugged: %{pid => MapSet.new()}}

      event = %TraceCalled{
        trace_id: -1,
        module: TestLV,
        function: :render,
        arity: 1,
        cid: nil,
        pid: pid,
        ets_ref: nil,
        transport_pid: nil
      }

      MockBus
      |> deny(:broadcast_event!, 2)

      assert {:noreply, ^state} = ProcessMonitor.handle_info(event, state)
    end

    test "with TraceCalled for render with nil cid and unknown pid" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      state = %{debugged: %{pid1 => MapSet.new()}}

      event = %TraceCalled{
        trace_id: -1,
        module: TestLV,
        function: :render,
        arity: 1,
        cid: nil,
        pid: pid2,
        ets_ref: nil,
        transport_pid: nil
      }

      MockBus
      |> expect(:broadcast_event!, fn %LiveViewBorn{pid: ^pid2} -> :ok end)

      MockAPILiveViewDebug
      |> expect(:live_components, fn ^pid2 -> {:ok, [%{cid: 1}, %{cid: 2}]} end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)

      assert new_state == %{
               debugged: %{
                 pid1 => MapSet.new(),
                 pid2 =>
                   MapSet.new([
                     %Phoenix.LiveComponent.CID{cid: 1},
                     %Phoenix.LiveComponent.CID{cid: 2}
                   ])
               }
             }
    end

    test "with TraceCalled for delete_component with known cid" do
      pid = self()
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      state = %{debugged: %{pid => MapSet.new([cid])}}

      event = %TraceCalled{
        trace_id: -1,
        module: Phoenix.LiveView.Diff,
        function: :delete_component,
        arity: 2,
        cid: cid,
        pid: pid,
        ets_ref: nil,
        transport_pid: nil
      }

      MockBus
      |> expect(:broadcast_event!, fn %LiveComponentDeleted{cid: ^cid, pid: ^pid}, ^pid -> :ok end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)
      assert new_state == %{debugged: %{pid => MapSet.new()}}
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
        arity: 2,
        cid: cid2,
        pid: pid,
        ets_ref: nil,
        transport_pid: nil
      }

      MockBus
      |> deny(:broadcast_event!, 2)

      assert {:noreply, ^state} = ProcessMonitor.handle_info(event, state)
    end

    test "with TraceCalled for delete_component with unknown pid" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      state = %{debugged: %{pid1 => MapSet.new([cid])}}

      event = %TraceCalled{
        trace_id: -1,
        module: Phoenix.LiveView.Diff,
        function: :delete_component,
        arity: 2,
        cid: cid,
        pid: pid2,
        ets_ref: nil,
        transport_pid: nil
      }

      MockBus
      |> deny(:broadcast_event!, 2)

      assert {:noreply, ^state} = ProcessMonitor.handle_info(event, state)
    end

    test "with DebuggerMounted" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      state = %{debugged: %{}, debugger: MapSet.new()}

      event = %DebuggerMounted{debugger_pid: pid1, debugged_pid: pid2}

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)
      assert new_state == %{debugged: %{}, debugger: MapSet.new([pid1])}
    end

    test "with DOWN message for debugger pid" do
      pid = self()
      state = %{debugged: %{}, debugger: MapSet.new([pid])}

      event = {:DOWN, 1, :process, pid, :normal}

      MockBus
      |> expect(:broadcast_event!, fn %DebuggerTerminated{debugger_pid: ^pid} -> :ok end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)
      assert new_state == %{debugged: %{}, debugger: MapSet.new()}
    end

    test "with DOWN message for debugged pid" do
      pid = :c.pid(0, 11, 0)
      state = %{debugged: %{pid => MapSet.new()}, debugger: MapSet.new()}

      event = {:DOWN, 1, :process, pid, :normal}

      MockBus
      |> expect(:broadcast_event!, fn %LiveViewDied{pid: ^pid} -> :ok end)

      assert {:noreply, new_state} = ProcessMonitor.handle_info(event, state)
      assert new_state == %{debugged: %{}, debugger: MapSet.new()}
    end
  end
end
