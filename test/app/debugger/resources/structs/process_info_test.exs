defmodule LiveDebugger.App.Debugger.Resources.Structs.ProcessInfoTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.App.Debugger.Resources.Structs.ProcessInfo

  describe "new/1" do
    test "creates ProcessInfo struct with all fields" do
      process_info_data = [
        current_function: {GenServer, :loop, 7},
        initial_call: {GenServer, :init_it, 6},
        registered_name: :test_process,
        status: :running,
        message_queue_len: 5,
        priority: :high,
        reductions: 1234,
        memory: 5000,
        total_heap_size: 100,
        heap_size: 80,
        stack_size: 20
      ]

      result = ProcessInfo.new(process_info_data)

      assert %ProcessInfo{
               current_function: {GenServer, :loop, 7},
               initial_call: {GenServer, :init_it, 6},
               registered_name: :test_process,
               status: :running,
               message_queue_len: 5,
               priority: :high,
               reductions: 1234,
               memory: 5000
             } = result

      word_size = :erlang.system_info(:wordsize)
      assert result.total_heap_size == 100 * word_size
      assert result.heap_size == 80 * word_size
      assert result.stack_size == 20 * word_size
    end
  end
end
