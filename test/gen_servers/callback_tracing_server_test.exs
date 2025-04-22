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

    CallbackTracingServer.start_link()
    :ok
  end

  describe "table!/1" do
    test "creates and remembers table for given pid" do
      pid =
        spawn(fn ->
          receive do
            :stop ->
              :ok
          end
        end)

      ref1 = CallbackTracingServer.table!(pid)

      assert ref1 == CallbackTracingServer.table!(pid)
      assert [] == :ets.tab2list(ref1)

      send(pid, :stop)
    end

    test "creates different tables for different pids" do
      [pid1, pid2] =
        for _ <- 1..2 do
          spawn(fn ->
            receive do
              :stop ->
                :ok
            end
          end)
        end

      ref1 = CallbackTracingServer.table!(pid1)
      ref2 = CallbackTracingServer.table!(pid2)

      assert ref1 != ref2
      assert ref1 == CallbackTracingServer.table!(pid1)
      assert ref2 == CallbackTracingServer.table!(pid2)
      assert [] == :ets.tab2list(ref1)
      assert [] == :ets.tab2list(ref2)

      send(pid1, :stop)
      send(pid2, :stop)
    end

    test "removes table after process exits" do
      pid =
        spawn(fn ->
          receive do
            :stop ->
              :ok
          end
        end)

      ref = CallbackTracingServer.table!(pid)

      send(pid, :stop)

      Process.sleep(1000)

      assert_raise ArgumentError, fn -> :ets.tab2list(ref) end
      assert ref != CallbackTracingServer.table!(pid)
    end
  end

  test "delete_table!/1" do
    pid =
      spawn(fn ->
        receive do
          :stop ->
            :ok
        end
      end)

    ref = CallbackTracingServer.table!(pid)

    assert :ok == CallbackTracingServer.delete_table!(pid)
    assert_raise ArgumentError, fn -> :ets.tab2list(ref) end
    assert ref != CallbackTracingServer.table!(pid)

    send(pid, :stop)
  end
end
