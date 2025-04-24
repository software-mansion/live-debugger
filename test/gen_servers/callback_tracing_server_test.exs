defmodule LiveDebugger.GenServers.CallbackTracingServerTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import Mox

  alias LiveDebugger.GenServers.CallbackTracingServer

  setup_all do
    LiveDebugger.MockModuleService
    |> stub(:all, fn -> [{to_charlist(CoolApp.Dashboard), "", false}] end)
    |> stub(:loaded?, fn _module -> true end)
    |> stub(:behaviours, fn _module -> [Phoenix.LiveView] end)

    allow(LiveDebugger.MockModuleService, self(), fn ->
      GenServer.whereis(CallbackTracingServer)
    end)

    start_supervised(CallbackTracingServer)

    :ok
  end

  setup do
    pid = spawn(fn -> Process.sleep(:infinity) end)

    on_exit(fn -> Process.exit(pid, :kill) end)

    %{pid: pid}
  end

  test "gen server is started" do
    pid = GenServer.whereis(CallbackTracingServer)
    assert {:error, {:already_started, ^pid}} = CallbackTracingServer.start_link()
    assert is_pid(pid)
  end

  describe "table!/1" do
    test "creates and remembers table for given pid", %{pid: pid} do
      ref1 = CallbackTracingServer.table!(pid)

      assert ref1 == CallbackTracingServer.table!(pid)
      assert [] == :ets.tab2list(ref1)
    end

    test "creates different tables for different pids", %{pid: pid1} do
      pid2 =
        spawn(fn ->
          receive do
            :stop ->
              :ok
          end
        end)

      ref1 = CallbackTracingServer.table!(pid1)
      ref2 = CallbackTracingServer.table!(pid2)

      assert ref1 != ref2
      assert ref1 == CallbackTracingServer.table!(pid1)
      assert ref2 == CallbackTracingServer.table!(pid2)
      assert [] == :ets.tab2list(ref1)
      assert [] == :ets.tab2list(ref2)

      send(pid2, :stop)
    end

    test "removes table after process exits", %{pid: pid} do
      ref = CallbackTracingServer.table!(pid)

      Process.exit(pid, :kill)

      Process.sleep(200)

      assert_raise ArgumentError, fn -> :ets.tab2list(ref) end
      assert ref != CallbackTracingServer.table!(pid)
    end
  end

  test "delete_table!/1", %{pid: pid} do
    ref = CallbackTracingServer.table!(pid)

    assert :ok == CallbackTracingServer.delete_table!(pid)
    assert_raise ArgumentError, fn -> :ets.tab2list(ref) end
    assert ref != CallbackTracingServer.table!(pid)
  end

  test "ping!/1" do
    assert :ok == CallbackTracingServer.ping!()
  end

  describe "tracing mechanism" do
    test "properly tracing callback call" do
      Process.sleep(200)
      CoolApp.Dashboard.handle_info(:msg, %{transport_pid: self()})

      assert [{0, trace}] = CallbackTracingServer.table!(self()) |> :ets.tab2list()

      assert trace.id == 0
      assert trace.module == CoolApp.Dashboard
      assert trace.function == :handle_info
      assert trace.arity == 2
      assert trace.args == [:msg, %{transport_pid: self()}]
      assert trace.socket_id == nil
      assert trace.transport_pid == self()
      assert trace.pid == self()
      assert trace.cid == nil
    end

    test "ignoring non-traced callbacks" do
      Process.sleep(200)
      CoolApp.Dashboard.non_traced_function(:arg)

      assert [] == CallbackTracingServer.table!(self()) |> :ets.tab2list()
    end
  end
end

defmodule CoolApp.Dashboard do
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def non_traced_function(_arg) do
    :ok
  end
end
