defmodule LiveDebugger.App.Debugger.Resources.Queries.ProcessInfoTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  alias LiveDebugger.App.Debugger.Resources.Queries.ProcessInfo, as: ProcessInfoQueries
  alias LiveDebugger.App.Debugger.Resources.Structs.ProcessInfo
  alias LiveDebugger.MockAPIProcessInfo

  describe "get_info/1" do
    test "returns ProcessInfo struct when API returns ok" do
      pid = self()

      process_info_data = [
        current_function: {GenServer, :loop, 7},
        initial_call: {GenServer, :init_it, 6},
        registered_name: :test_process,
        status: :running,
        message_queue_len: 0,
        priority: :normal,
        reductions: 1234,
        memory: 5000,
        total_heap_size: 100,
        heap_size: 80,
        stack_size: 20
      ]

      MockAPIProcessInfo
      |> expect(:get_info, fn ^pid -> {:ok, process_info_data} end)

      assert {:ok, %ProcessInfo{} = result} = ProcessInfoQueries.get_info(pid)
      assert result.current_function == {GenServer, :loop, 7}
      assert result.initial_call == {GenServer, :init_it, 6}
      assert result.registered_name == :test_process
      assert result.status == :running
    end

    test "returns error when API returns error" do
      pid = :c.pid(0, 0, 1)

      MockAPIProcessInfo
      |> expect(:get_info, fn ^pid -> {:error, "Could not find process"} end)

      assert {:error, "Could not find process"} = ProcessInfoQueries.get_info(pid)
    end
  end
end
