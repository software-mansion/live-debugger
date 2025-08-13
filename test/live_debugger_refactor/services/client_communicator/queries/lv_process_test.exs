defmodule LiveDebuggerRefactor.Services.ClientCommunicator.Queries.LvProcessTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Services.ClientCommunicator.Queries.LvProcess, as: LvProcessQueries
  alias LiveDebuggerRefactor.Structs.LvProcess
  alias LiveDebuggerRefactor.Fakes
  alias LiveDebuggerRefactor.MockAPILiveViewDiscovery
  alias LiveDebuggerRefactor.MockAPILiveViewDebug

  setup :verify_on_exit!

  describe "get_by_socket_id/1" do
    test "returns LvProcess when socket_id matches" do
      socket_id = "phx-GBsi_6M7paYhySQj"

      lv_process = %LvProcess{
        socket_id: socket_id,
        pid: :c.pid(0, 123, 0),
        module: LiveDebuggerTest.LiveView
      }

      other_lv_process = %LvProcess{
        socket_id: "phx-other-socket",
        pid: :c.pid(0, 124, 0),
        module: LiveDebuggerTest.OtherLiveView
      }

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, fn ->
        [lv_process, other_lv_process]
      end)

      assert {:ok, ^lv_process} = LvProcessQueries.get_by_socket_id(socket_id)
    end

    test "returns :not_found when socket_id does not match any process" do
      socket_id = "phx-nonexistent-socket"

      lv_process = %LvProcess{
        socket_id: "phx-existing-socket",
        pid: :c.pid(0, 123, 0),
        module: LiveDebuggerTest.LiveView
      }

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, fn ->
        [lv_process]
      end)

      assert :not_found = LvProcessQueries.get_by_socket_id(socket_id)
    end

    test "returns :not_found when no processes exist" do
      socket_id = "phx-any-socket"

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, fn ->
        []
      end)

      assert :not_found = LvProcessQueries.get_by_socket_id(socket_id)
    end

    test "returns :not_found when multiple processes have the same socket_id" do
      socket_id = "phx-duplicate-socket"

      lv_process_1 = %LvProcess{
        socket_id: socket_id,
        pid: :c.pid(0, 123, 0),
        module: LiveDebuggerTest.LiveView
      }

      lv_process_2 = %LvProcess{
        socket_id: socket_id,
        pid: :c.pid(0, 124, 0),
        module: LiveDebuggerTest.OtherLiveView
      }

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, fn ->
        [lv_process_1, lv_process_2]
      end)

      assert :not_found = LvProcessQueries.get_by_socket_id(socket_id)
    end
  end

  describe "get_live_component/2" do
    test "returns component when cid exists" do
      lv_process = %LvProcess{
        pid: :c.pid(0, 123, 0),
        socket_id: "phx-socket-id"
      }

      cid = 1
      components = Fakes.live_components()
      expected_component = Enum.find(components, fn component -> component.cid == cid end)

      MockAPILiveViewDebug
      |> expect(:live_components, fn pid when pid == lv_process.pid ->
        {:ok, components}
      end)

      assert {:ok, ^expected_component} = LvProcessQueries.get_live_component(lv_process, cid)
    end

    test "returns :not_found when cid does not exist" do
      lv_process = %LvProcess{
        pid: :c.pid(0, 123, 0),
        socket_id: "phx-socket-id"
      }

      cid = 999
      components = Fakes.live_components()

      MockAPILiveViewDebug
      |> expect(:live_components, fn pid when pid == lv_process.pid ->
        {:ok, components}
      end)

      assert :not_found = LvProcessQueries.get_live_component(lv_process, cid)
    end

    test "returns :not_found when components list is empty" do
      lv_process = %LvProcess{
        pid: :c.pid(0, 123, 0),
        socket_id: "phx-socket-id"
      }

      cid = 1

      MockAPILiveViewDebug
      |> expect(:live_components, fn pid when pid == lv_process.pid ->
        {:ok, []}
      end)

      assert :not_found = LvProcessQueries.get_live_component(lv_process, cid)
    end
  end
end
