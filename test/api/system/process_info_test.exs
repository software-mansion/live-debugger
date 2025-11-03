defmodule LiveDebugger.API.System.ProcessInfoImplTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.API.System.ProcessInfo.Impl, as: ProcessInfoImpl

  defmodule TestServer do
    use GenServer

    def start_link(opts) do
      GenServer.start_link(__MODULE__, opts, name: opts[:name])
    end

    def init(_opts) do
      {:ok, %{data: "test"}}
    end

    def handle_call(:get_state, _from, state) do
      {:reply, state, state}
    end
  end

  setup_all do
    alive_pid = start_supervised!({TestServer, name: TestServerAlive}, id: TestServerAlive)
    dead_pid = start_supervised!({TestServer, name: TestServerDead}, id: TestServerDead)

    :ok = stop_supervised!(TestServerDead)

    %{alive_pid: alive_pid, dead_pid: dead_pid}
  end

  describe "get_info/1" do
    test "returns ok tuple with keyword list for a live process", %{alive_pid: alive_pid} do
      assert {:ok, info} = ProcessInfoImpl.get_info(alive_pid)

      assert Keyword.has_key?(info, :heap_size)
      assert Keyword.has_key?(info, :memory)
      assert Keyword.has_key?(info, :status)
    end

    test "returns error for a dead process", %{dead_pid: dead_pid} do
      assert Process.alive?(dead_pid) == false
      assert {:error, "Could not find process"} = ProcessInfoImpl.get_info(dead_pid)
    end
  end
end
