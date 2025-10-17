defmodule LiveDebugger.API.System.ProcessImplTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.API.System.Process.Impl, as: ProcessImpl

  defmodule TestServer do
    @moduledoc false
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

  def task_func do
    IO.puts("task running ...")
    Process.sleep(:inifnity)
  end

  describe "initial_call/1" do
    test "returns $initial_call for a live process", %{alive_pid: alive_pid} do
      assert {:ok, {TestServer, :init, 1}} = ProcessImpl.initial_call(alive_pid)
    end

    test "returns :error for a dead process", %{dead_pid: dead_pid} do
      assert Process.alive?(dead_pid) == false
      assert {:error, :not_alive} = ProcessImpl.initial_call(dead_pid)
    end

    test "returns :error for a process with no initial call" do
      pid = spawn(fn -> Process.sleep(:infinity) end)
      assert {:error, :no_initial_call} = ProcessImpl.initial_call(pid)
    end
  end

  describe "state/1" do
    test "returns state of for a live process", %{alive_pid: alive_pid} do
      assert {:ok, %{number: 14}} = ProcessImpl.state(alive_pid)
    end

    test "returns :error for a dead process", %{dead_pid: dead_pid} do
      assert {:error, :not_alive} = ProcessImpl.state(dead_pid)
    end
  end
end
