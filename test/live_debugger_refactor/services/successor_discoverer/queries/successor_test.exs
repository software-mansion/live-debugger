defmodule LiveDebuggerRefactor.Services.SuccessorDiscoverer.Queries.SuccessorTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.MockAPILiveViewDiscovery
  alias LiveDebuggerRefactor.Services.SuccessorDiscoverer.Queries.Successor
  alias LiveDebuggerRefactor.Structs.LvProcess

  setup :verify_on_exit!

  describe "find_successor/1" do
    test "returns nil when no processes with matching transport_pid exist" do
      transport_pid = :c.pid(0, 123, 0)
      other_transport_pid = :c.pid(0, 456, 0)

      lv_process = %LvProcess{
        socket_id: "phx-123",
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        [
          %LvProcess{
            socket_id: "phx-456",
            transport_pid: other_transport_pid,
            nested?: false,
            embedded?: false
          }
        ]
      end)

      assert Successor.find_successor(lv_process) == nil
    end

    test "returns non-nested, non-embedded process with matching transport_pid (priority 1)" do
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: "phx-123",
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        [
          %LvProcess{
            socket_id: "phx-successor",
            transport_pid: transport_pid,
            nested?: false,
            embedded?: false
          },
          %LvProcess{
            socket_id: "phx-nested",
            transport_pid: transport_pid,
            nested?: true,
            embedded?: false
          },
          %LvProcess{
            socket_id: "phx-embedded",
            transport_pid: transport_pid,
            nested?: false,
            embedded?: true
          }
        ]
      end)

      result = Successor.find_successor(lv_process)

      assert %LvProcess{
               socket_id: "phx-successor",
               transport_pid: ^transport_pid,
               nested?: false,
               embedded?: false
             } = result
    end

    test "returns single process with matching transport_pid when no non-nested, non-embedded process exists (priority 2)" do
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: "phx-123",
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        [
          %LvProcess{
            socket_id: "phx-nested",
            transport_pid: transport_pid,
            nested?: true,
            embedded?: false
          }
        ]
      end)

      result = Successor.find_successor(lv_process)

      assert %LvProcess{
               socket_id: "phx-nested",
               transport_pid: ^transport_pid,
               nested?: true,
               embedded?: false
             } = result
    end

    test "returns nil when multiple processes with matching transport_pid exist but none are non-nested, non-embedded" do
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: "phx-123",
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        [
          %LvProcess{
            socket_id: "phx-nested-1",
            transport_pid: transport_pid,
            nested?: true,
            embedded?: false
          },
          %LvProcess{
            socket_id: "phx-nested-2",
            transport_pid: transport_pid,
            nested?: true,
            embedded?: false
          }
        ]
      end)

      assert Successor.find_successor(lv_process) == nil
    end

    test "returns nil when multiple processes with matching transport_pid exist and all are nested and embedded" do
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: "phx-123",
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        [
          %LvProcess{
            socket_id: "phx-nested-embedded-1",
            transport_pid: transport_pid,
            nested?: true,
            embedded?: true
          },
          %LvProcess{
            socket_id: "phx-nested-embedded-2",
            transport_pid: transport_pid,
            nested?: true,
            embedded?: true
          }
        ]
      end)

      assert Successor.find_successor(lv_process) == nil
    end

    test "prioritizes non-nested, non-embedded over single process" do
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: "phx-123",
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        [
          %LvProcess{
            socket_id: "phx-priority-1",
            transport_pid: transport_pid,
            nested?: false,
            embedded?: false
          },
          %LvProcess{
            socket_id: "phx-single",
            transport_pid: transport_pid,
            nested?: true,
            embedded?: false
          }
        ]
      end)

      result = Successor.find_successor(lv_process)

      assert %LvProcess{
               socket_id: "phx-priority-1",
               transport_pid: ^transport_pid,
               nested?: false,
               embedded?: false
             } = result
    end

    test "handles empty list of processes" do
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: "phx-123",
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        []
      end)

      assert Successor.find_successor(lv_process) == nil
    end
  end
end
