defmodule LiveDebugger.Structs.LvProcessTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Structs.LvProcess

  describe "new/2" do
    test "creates a new LvProcess struct with the given pid and socket" do
      pid = self()

      socket = %Phoenix.LiveView.Socket{
        id: "socket_id",
        root_pid: pid,
        parent_pid: nil,
        transport_pid: nil,
        view: LiveDebuggerTest.TestView,
        host_uri: :not_mounted_at_router
      }

      lv_process = LvProcess.new(pid, socket)

      assert %LvProcess{
               socket_id: "socket_id",
               root_pid: ^pid,
               parent_pid: nil,
               pid: ^pid,
               transport_pid: nil,
               module: LiveDebuggerTest.TestView,
               nested?: false,
               debugger?: false,
               embedded?: true
             } = lv_process
    end
  end

  describe "new/1" do
    test "returns nil if the process is not found" do
      LiveDebugger.MockStateServer
      |> expect(:get, fn _pid ->
        {:error, :not_found}
      end)

      assert LvProcess.new(self()) == nil
    end

    test "returns a new LvProcess struct if the process is found" do
      socket_id = "socket_id"
      pid = self()
      root_pid = pid
      parent_pid = nil
      transport_pid = nil
      module = LiveDebuggerTest.TestView

      LiveDebugger.MockStateServer
      |> expect(:get, fn _pid ->
        {:ok,
         LiveDebugger.Fakes.state(
           socket_id: socket_id,
           root_pid: root_pid,
           parent_pid: parent_pid,
           transport_pid: transport_pid,
           module: module
         )}
      end)

      assert %LvProcess{
               socket_id: ^socket_id,
               root_pid: ^root_pid,
               parent_pid: ^parent_pid,
               pid: ^pid,
               transport_pid: ^transport_pid,
               module: ^module,
               nested?: false,
               debugger?: false,
               embedded?: false
             } = LvProcess.new(pid)
    end

    test "sets embedded? when LiveView process is Embedded Live View" do
      socket_id = "socket_id"
      pid = self()
      root_pid = pid
      parent_pid = nil
      transport_pid = :c.pid(0, 7, 0)
      module = LiveDebuggerTest.TestView

      LiveDebugger.MockStateServer
      |> expect(:get, fn _pid ->
        {:ok,
         LiveDebugger.Fakes.state(
           socket_id: socket_id,
           root_pid: root_pid,
           parent_pid: parent_pid,
           transport_pid: transport_pid,
           module: module,
           host_uri: :not_mounted_at_router
         )}
      end)

      assert %LvProcess{
               socket_id: ^socket_id,
               root_pid: ^root_pid,
               parent_pid: ^parent_pid,
               pid: ^pid,
               transport_pid: ^transport_pid,
               module: ^module,
               nested?: false,
               debugger?: false,
               embedded?: true
             } = LvProcess.new(pid)
    end

    test "sets debugger? when LiveView process is LiveDebugger process" do
      socket_id = "socket_id"
      pid = self()
      root_pid = pid
      parent_pid = nil
      transport_pid = nil
      module = LiveDebugger.TestView

      LiveDebugger.MockStateServer
      |> expect(:get, fn _pid ->
        {:ok,
         LiveDebugger.Fakes.state(
           socket_id: socket_id,
           root_pid: root_pid,
           parent_pid: parent_pid,
           transport_pid: transport_pid,
           module: module
         )}
      end)

      assert %LvProcess{
               socket_id: ^socket_id,
               root_pid: ^root_pid,
               parent_pid: ^parent_pid,
               pid: ^pid,
               transport_pid: ^transport_pid,
               module: ^module,
               nested?: false,
               debugger?: true,
               embedded?: false
             } = LvProcess.new(pid)
    end

    test "sets nested? when LiveView process is a Nested Live View" do
      socket_id = "socket_id"
      pid = :c.pid(0, 0, 1)
      parent_pid = :c.pid(0, 0, 0)
      root_pid = parent_pid
      transport_pid = nil
      module = LiveDebuggerTest.TestView

      LiveDebugger.MockStateServer
      |> expect(:get, fn _pid ->
        {:ok,
         LiveDebugger.Fakes.state(
           socket_id: socket_id,
           root_pid: root_pid,
           parent_pid: parent_pid,
           transport_pid: transport_pid,
           module: module
         )}
      end)

      assert %LvProcess{
               socket_id: ^socket_id,
               root_pid: ^root_pid,
               parent_pid: ^parent_pid,
               pid: ^pid,
               transport_pid: ^transport_pid,
               module: ^module,
               nested?: true,
               debugger?: false,
               embedded?: false
             } = LvProcess.new(pid)
    end
  end

  describe "parent/1" do
    test "returns the parent process of the given LvProcess" do
      socket_id = "socket_id"
      pid = :c.pid(0, 0, 1)
      parent_pid = :c.pid(0, 0, 0)
      root_pid = parent_pid
      transport_pid = nil
      module = LiveDebuggerTest.TestView

      LiveDebugger.MockStateServer
      |> expect(:get, fn ^parent_pid ->
        {:ok,
         LiveDebugger.Fakes.state(
           socket_id: socket_id,
           root_pid: root_pid,
           parent_pid: nil,
           transport_pid: transport_pid,
           module: module
         )}
      end)

      lv_process = %LvProcess{
        socket_id: socket_id,
        root_pid: root_pid,
        parent_pid: parent_pid,
        pid: pid,
        transport_pid: transport_pid,
        module: module,
        nested?: true,
        debugger?: false,
        embedded?: false
      }

      assert %LvProcess{
               pid: ^parent_pid
             } = LvProcess.parent(lv_process)
    end

    test "returns nil if no parent" do
      lv_process = %LvProcess{
        socket_id: "socket_id",
        root_pid: self(),
        parent_pid: nil,
        pid: self(),
        transport_pid: nil,
        module: LiveDebuggerTest.TestView,
        nested?: false,
        debugger?: false,
        embedded?: false
      }

      assert LvProcess.parent(lv_process) == nil
    end
  end
end
