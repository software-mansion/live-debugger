defmodule LiveDebugger.Services.ProcessMonitor.GenServers.DebuggedProcessesMonitorTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Utils.Versions
  alias LiveDebugger.Services.ProcessMonitor.GenServers.DebuggedProcessesMonitor
  alias LiveDebugger.MockAPILiveViewDebug

  alias LiveDebugger.MockBus
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentDeleted
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentCreated
  alias LiveDebugger.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebugger.Services.TelemetryHandler.Events.TelemetryEmitted

  setup :verify_on_exit!

  test "init/1" do
    expect(MockBus, :receive_events!, fn -> :ok end)
    expect(MockBus, :receive_traces!, fn -> :ok end)

    assert {:ok, %{}} = DebuggedProcessesMonitor.init([])
  end

  describe "handle_info/2" do
    if Versions.live_component_destroyed_telemetry_supported?() do
      test "with TelemetryEmitted{type: :destroyed} event" do
        pid = self()
        cid = %Phoenix.LiveComponent.CID{cid: 1}
        state = %{pid => %{components: MapSet.new([cid])}}

        event = %TelemetryEmitted{source: :live_component, type: :destroyed, cid: cid, pid: pid}

        MockBus
        |> expect(:broadcast_event!, fn %LiveComponentDeleted{cid: ^cid, pid: ^pid}, ^pid ->
          :ok
        end)

        assert {:noreply, new_state} = DebuggedProcessesMonitor.handle_info(event, state)
        assert new_state == %{pid => %{components: MapSet.new()}}
      end
    end

    test "with TraceCalled for render with known cid" do
      pid = self()
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      state = %{pid => %{components: MapSet.new([cid])}}

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

      assert {:noreply, ^state} = DebuggedProcessesMonitor.handle_info(event, state)
    end

    test "with TraceCalled for render with unknown cid" do
      pid = self()
      cid1 = %Phoenix.LiveComponent.CID{cid: 1}
      cid2 = %Phoenix.LiveComponent.CID{cid: 2}
      state = %{pid => %{components: MapSet.new([cid1])}}

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

      assert {:noreply, new_state} = DebuggedProcessesMonitor.handle_info(event, state)
      assert new_state == %{pid => %{components: MapSet.new([cid1, cid2])}}
    end

    test "with TraceCalled for render with unknown pid" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      tpid1 = :c.pid(0, 10, 0)
      cid1 = %Phoenix.LiveComponent.CID{cid: 1}
      state = %{pid1 => %{components: MapSet.new([cid1])}}

      event = %TraceCalled{
        trace_id: -1,
        module: TestLV.Component,
        function: :render,
        arity: 1,
        cid: cid1,
        pid: pid2,
        ets_ref: nil,
        transport_pid: tpid1
      }

      MockBus
      |> expect(:broadcast_event!, fn %LiveViewBorn{pid: ^pid2, transport_pid: ^tpid1} -> :ok end)

      MockAPILiveViewDebug
      |> expect(:live_components, fn ^pid2 -> {:ok, [%{cid: 1}, %{cid: 2}]} end)

      assert {:noreply, new_state} = DebuggedProcessesMonitor.handle_info(event, state)

      assert new_state == %{
               pid1 => %{components: MapSet.new([cid1])},
               pid2 => %{
                 transport_pid: tpid1,
                 components:
                   MapSet.new([
                     %Phoenix.LiveComponent.CID{cid: 1},
                     %Phoenix.LiveComponent.CID{cid: 2}
                   ])
               }
             }
    end

    test "with TraceCalled for render with nil cid and known pid" do
      pid = self()
      state = %{pid => %{components: MapSet.new()}}

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

      assert {:noreply, ^state} = DebuggedProcessesMonitor.handle_info(event, state)
    end

    test "with TraceCalled for render with nil cid and unknown pid" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      tpid1 = :c.pid(0, 9, 0)
      tpid2 = :c.pid(0, 10, 0)
      state = %{pid1 => %{transport_pid: tpid1, components: MapSet.new()}}

      event = %TraceCalled{
        trace_id: -1,
        module: TestLV,
        function: :render,
        arity: 1,
        cid: nil,
        pid: pid2,
        ets_ref: nil,
        transport_pid: tpid2
      }

      MockBus
      |> expect(:broadcast_event!, fn %LiveViewBorn{pid: ^pid2} -> :ok end)

      MockAPILiveViewDebug
      |> expect(:live_components, fn ^pid2 -> {:ok, [%{cid: 1}, %{cid: 2}]} end)

      assert {:noreply, new_state} = DebuggedProcessesMonitor.handle_info(event, state)

      assert new_state == %{
               pid1 => %{transport_pid: tpid1, components: MapSet.new()},
               pid2 => %{
                 transport_pid: tpid2,
                 components:
                   MapSet.new([
                     %Phoenix.LiveComponent.CID{cid: 1},
                     %Phoenix.LiveComponent.CID{cid: 2}
                   ])
               }
             }
    end

    if not Versions.live_component_destroyed_telemetry_supported?() do
      test "with TraceCalled for delete_component with known cid" do
        pid = self()
        cid = %Phoenix.LiveComponent.CID{cid: 1}
        state = %{pid => %{components: MapSet.new([cid])}}

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
        |> expect(:broadcast_event!, fn %LiveComponentDeleted{cid: ^cid, pid: ^pid}, ^pid ->
          :ok
        end)

        assert {:noreply, new_state} = DebuggedProcessesMonitor.handle_info(event, state)
        assert new_state == %{pid => %{components: MapSet.new()}}
      end

      test "with TraceCalled for delete_component with unknown cid" do
        pid = self()
        cid1 = %Phoenix.LiveComponent.CID{cid: 1}
        cid2 = %Phoenix.LiveComponent.CID{cid: 2}
        state = %{pid => %{components: MapSet.new([cid1])}}

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

        assert {:noreply, ^state} = DebuggedProcessesMonitor.handle_info(event, state)
      end

      test "with TraceCalled for delete_component with unknown pid" do
        pid1 = :c.pid(0, 11, 0)
        pid2 = :c.pid(0, 12, 0)
        cid = %Phoenix.LiveComponent.CID{cid: 1}
        state = %{pid1 => %{components: MapSet.new([cid])}}

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

        assert {:noreply, ^state} = DebuggedProcessesMonitor.handle_info(event, state)
      end
    end

    test "with DOWN message" do
      pid = self()
      tpid = :c.pid(0, 10, 0)
      state = %{pid => %{transport_pid: tpid, components: MapSet.new()}}

      event = {:DOWN, 1, :process, pid, :normal}

      MockBus
      |> expect(:broadcast_event!, fn %LiveViewDied{pid: ^pid, transport_pid: ^tpid} -> :ok end)

      assert {:noreply, new_state} = DebuggedProcessesMonitor.handle_info(event, state)
      assert new_state == %{}
    end
  end
end
