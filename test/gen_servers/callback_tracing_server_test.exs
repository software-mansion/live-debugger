defmodule LiveDebugger.GenServers.CallbackTracingServerTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.GenServers.CallbackTracingServer

  setup_all do
    LiveDebugger.MockModuleService
    |> stub(:all, fn -> [] end)

    allow(LiveDebugger.MockModuleService, self(), fn ->
      GenServer.whereis(CallbackTracingServer)
    end)

    start_supervised(CallbackTracingServer)

    :ok
  end

  setup do
    pid =
      spawn(fn ->
        receive do
          :stop ->
            :ok
        end
      end)

    on_exit(fn -> send(pid, :stop) end)

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

      send(pid, :stop)

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
end
