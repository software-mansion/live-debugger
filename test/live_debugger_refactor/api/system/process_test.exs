defmodule LiveDebugger.API.System.ProcessImplTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.API.System.Process.Impl, as: ProcessImpl

  defmodule TestServer do
    use GenServer

    def start_link(opts) do
      GenServer.start_link(__MODULE__, opts)
    end

    def init(_opts) do
      {:ok, %{number: 14}}
    end
  end

  setup_all do
    alive_pid = start_supervised!(TestServer, id: TestServerAlive)
    dead_pid = start_supervised!(TestServer, id: TestServerDead)

    :ok = stop_supervised!(TestServerDead)

    %{alive_pid: alive_pid, dead_pid: dead_pid}
  end

  describe "initial_call/1" do
    test "returns $initial_call for a live process", %{alive_pid: alive_pid} do
      assert {TestServer, :init, 1} = ProcessImpl.initial_call(alive_pid)
    end

    test "returns nil for a dead process", %{dead_pid: dead_pid} do
      assert Process.alive?(dead_pid) == false
      assert ProcessImpl.initial_call(dead_pid) == nil
    end
  end

  describe "state/1" do
    test "returns state of for a live process", %{alive_pid: alive_pid} do
      assert {:ok, state} = ProcessImpl.state(alive_pid)
      assert %{number: 14} = state
    end

    test "returns :error for a dead process", %{dead_pid: dead_pid} do
      assert {:error, :not_alive} = ProcessImpl.state(dead_pid)
    end
  end
end
