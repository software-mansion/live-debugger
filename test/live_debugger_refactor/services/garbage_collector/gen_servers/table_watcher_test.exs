defmodule LiveDebuggerRefactor.Services.GarbageCollector.GenServers.TableWatcherTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.App.Events.DebuggerTerminated
  alias LiveDebuggerRefactor.App.Events.DebuggerMounted
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebuggerRefactor.MockBus

  alias LiveDebuggerRefactor.Services.GarbageCollector.GenServers.TableWatcher
  alias LiveDebuggerRefactor.Services.GarbageCollector.GenServers.TableWatcher.ProcessInfo

  test "init/1" do
    expect(MockBus, :receive_events!, fn -> :ok end)

    assert {:ok, %{}} = TableWatcher.init([])
  end

  describe "handle_call/3" do
    test "for {:alive?, pid}" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      pid3 = :c.pid(0, 13, 0)

      state = %{
        pid1 => %ProcessInfo{alive?: true, watchers: MapSet.new()},
        pid2 => %ProcessInfo{alive?: false, watchers: MapSet.new()}
      }

      assert {:reply, true, ^state} = TableWatcher.handle_call({:alive?, pid1}, self(), state)
      assert {:reply, false, ^state} = TableWatcher.handle_call({:alive?, pid2}, self(), state)
      assert {:reply, false, ^state} = TableWatcher.handle_call({:alive?, pid3}, self(), state)
    end

    test "for {:watched?, pid}" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 12, 0)
      pid3 = :c.pid(0, 13, 0)
      pid4 = :c.pid(0, 14, 0)

      state = %{
        pid1 => %ProcessInfo{alive?: true, watchers: MapSet.new([pid2])},
        pid2 => %ProcessInfo{alive?: false, watchers: MapSet.new([pid1])},
        pid3 => %ProcessInfo{alive?: true, watchers: MapSet.new()}
      }

      assert {:reply, true, ^state} = TableWatcher.handle_call({:watched?, pid1}, self(), state)
      assert {:reply, true, ^state} = TableWatcher.handle_call({:watched?, pid2}, self(), state)
      assert {:reply, false, ^state} = TableWatcher.handle_call({:watched?, pid3}, self(), state)
      assert {:reply, false, ^state} = TableWatcher.handle_call({:watched?, pid4}, self(), state)
    end
  end

  describe "handle_info/2" do
    test "for LiveViewBorn event" do
      pid = self()
      state = %{}
      event = %LiveViewBorn{pid: pid}

      assert {:noreply, new_state} = TableWatcher.handle_info(event, state)

      assert new_state == %{pid => %ProcessInfo{alive?: true, watchers: MapSet.new()}}
    end

    test "for LiveViewDied event with no watchers" do
      pid = self()
      state = %{pid => %ProcessInfo{alive?: true, watchers: MapSet.new()}}
      event = %LiveViewDied{pid: pid}

      assert {:noreply, %{}} = TableWatcher.handle_info(event, state)
    end

    test "for LiveViewDied event with watchers" do
      pid = self()
      watcher_pid = :c.pid(0, 12, 0)
      state = %{pid => %ProcessInfo{alive?: true, watchers: MapSet.new([watcher_pid])}}
      event = %LiveViewDied{pid: pid}

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

      assert Process.alive?(debugged_pid) == false

      assert {:noreply, new_state} = TableWatcher.handle_info(event, state)

      assert new_state == %{}
    end

    test "for DebuggerTerminated event" do
      debugged_pid = self()
      debugger_pid = :c.pid(0, 12, 0)
      state = %{debugged_pid => %ProcessInfo{alive?: true, watchers: MapSet.new([debugger_pid])}}
      event = %DebuggerTerminated{debugged_pid: debugged_pid, debugger_pid: debugger_pid}

      assert {:noreply, new_state} = TableWatcher.handle_info(event, state)

      assert new_state == %{debugged_pid => %ProcessInfo{alive?: true, watchers: MapSet.new()}}
    end
  end
end
