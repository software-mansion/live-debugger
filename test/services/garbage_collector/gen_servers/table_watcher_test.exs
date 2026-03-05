defmodule LiveDebugger.Services.GarbageCollector.GenServers.TableWatcherTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.MockBus
  alias LiveDebugger.App.Events.DebuggerMounted
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.Services.ProcessMonitor.Events.DebuggerTerminated

  alias LiveDebugger.Services.GarbageCollector.GenServers.TableWatcher
  alias LiveDebugger.Services.GarbageCollector.GenServers.TableWatcher.ProcessInfo

  test "init/1" do
    expect(MockBus, :receive_events!, fn -> :ok end)

    assert {:ok, %{}} = TableWatcher.init([])
  end

  describe "handle_call/3" do
    test "for :alive_pids" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      pid3 = :c.pid(0, 13, 0)

      state = %{
        pid1 => %ProcessInfo{alive?: true, watchers: MapSet.new()},
        pid2 => %ProcessInfo{alive?: false, watchers: MapSet.new([pid3])}
      }

      assert {:reply, reply, ^state} = TableWatcher.handle_call(:alive_pids, self(), state)
      assert MapSet.equal?(reply, MapSet.new([pid1]))
    end

    test "for :watched_pids" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      pid3 = :c.pid(0, 13, 0)

      state = %{
        pid1 => %ProcessInfo{alive?: true, watchers: MapSet.new([pid2])},
        pid2 => %ProcessInfo{alive?: false, watchers: MapSet.new([pid1])},
        pid3 => %ProcessInfo{alive?: true, watchers: MapSet.new()}
      }

      assert {:reply, reply, ^state} = TableWatcher.handle_call(:watched_pids, self(), state)
      assert MapSet.equal?(reply, MapSet.new([pid1, pid2]))
    end
  end

  describe "handle_info/2" do
    test "for LiveViewBorn event" do
      pid = self()
      state = %{}
      event = %LiveViewBorn{pid: pid, transport_pid: nil}

      assert {:noreply, new_state} = TableWatcher.handle_info(event, state)

      assert new_state == %{pid => %ProcessInfo{alive?: true, watchers: MapSet.new()}}
    end

    test "for LiveViewDied event with no watchers" do
      pid = self()
      tpid = :c.pid(0, 10, 0)
      state = %{pid => %ProcessInfo{alive?: true, watchers: MapSet.new()}}
      event = %LiveViewDied{pid: pid, transport_pid: tpid}

      assert {:noreply, %{}} = TableWatcher.handle_info(event, state)
    end

    test "for LiveViewDied event with watchers" do
      pid = self()
      tpid = :c.pid(0, 10, 0)
      watcher_pid = :c.pid(0, 12, 0)
      state = %{pid => %ProcessInfo{alive?: true, watchers: MapSet.new([watcher_pid])}}
      event = %LiveViewDied{pid: pid, transport_pid: tpid}

      assert {:noreply, new_state} = TableWatcher.handle_info(event, state)

      assert new_state == %{
               pid => %ProcessInfo{alive?: false, watchers: MapSet.new([watcher_pid])}
             }
    end

    test "for DebuggerMounted event when pid is known" do
      debugged_pid = self()
      debugger_pid = :c.pid(0, 12, 0)
      state = %{debugged_pid => %ProcessInfo{alive?: true, watchers: MapSet.new()}}

      event = %DebuggerMounted{debugged_pid: debugged_pid, debugger_pid: debugger_pid}

      assert {:noreply, new_state} = TableWatcher.handle_info(event, state)

      assert new_state == %{
               debugged_pid => %ProcessInfo{alive?: true, watchers: MapSet.new([debugger_pid])}
             }
    end

    test "for DebuggerMounted event when pid is unknown and alive" do
      debugged_pid = self()
      debugger_pid = :c.pid(0, 12, 0)
      state = %{}

      event = %DebuggerMounted{debugged_pid: debugged_pid, debugger_pid: debugger_pid}

      assert {:noreply, new_state} = TableWatcher.handle_info(event, state)

      assert new_state == %{
               debugged_pid => %ProcessInfo{alive?: true, watchers: MapSet.new([debugger_pid])}
             }
    end

    test "for DebuggerMounted event when pid is unknown and not alive" do
      debugged_pid = spawn(fn -> :ok end)
      debugger_pid = :c.pid(0, 12, 0)
      state = %{}
      event = %DebuggerMounted{debugged_pid: debugged_pid, debugger_pid: debugger_pid}

      Process.exit(debugged_pid, :normal)
      Process.sleep(100)

      assert Process.alive?(debugged_pid) == false

      assert {:noreply, %{}} = TableWatcher.handle_info(event, state)
    end

    test "for debugger DebuggerTerminated event" do
      debugged_pid = self()
      debugger_pid = :c.pid(0, 12, 0)
      state = %{debugged_pid => %ProcessInfo{alive?: true, watchers: MapSet.new([debugger_pid])}}
      event = %DebuggerTerminated{debugger_pid: debugger_pid}

      assert {:noreply, new_state} = TableWatcher.handle_info(event, state)

      assert new_state == %{debugged_pid => %ProcessInfo{alive?: true, watchers: MapSet.new()}}
    end

    test "for debugger DebuggerTerminated event when `debugger_pid` is not in the state" do
      debugger_pid = :c.pid(0, 12, 0)
      other_debugger_pid = :c.pid(0, 13, 0)
      debugged_pid = :c.pid(0, 14, 0)

      state = %{
        debugged_pid => %ProcessInfo{alive?: true, watchers: MapSet.new([other_debugger_pid])}
      }

      event = %DebuggerTerminated{debugger_pid: debugger_pid}

      assert {:noreply, ^state} = TableWatcher.handle_info(event, state)
    end
  end
end
