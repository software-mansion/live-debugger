defmodule LiveDebugger.Services.ClientCommunicator.GenServers.ClientCommunicatorTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.ClientCommunicator.GenServers.ClientCommunicator
  alias LiveDebugger.Services.ClientCommunicator.Queries.LvProcess
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Fakes
  alias LiveDebugger.MockClient
  alias LiveDebugger.MockAPILiveViewDiscovery
  alias LiveDebugger.MockAPILiveViewDebug

  setup :verify_on_exit!

  describe "init/1" do
    test "properly initializes ClientCommunicator" do
      MockClient
      |> expect(:receive_events, fn -> :ok end)

      assert {:ok, _} = ClientCommunicator.init([])
    end
  end

  describe "handle_info/2 with request-node-element" do
    setup do
      socket_id = "phx-GBsi_6M7paYhySQj"
      root_socket_id = "phx-root-socket-id"

      lv_process = %LvProcess{
        socket_id: socket_id,
        pid: :c.pid(0, 123, 0),
        module: LiveDebuggerTest.LiveView
      }

      {:ok, socket_id: socket_id, root_socket_id: root_socket_id, lv_process: lv_process}
    end

    test "handles LiveView request when process found", %{
      socket_id: socket_id,
      root_socket_id: root_socket_id,
      lv_process: lv_process
    } do
      payload = %{
        "socket_id" => socket_id,
        "root_socket_id" => root_socket_id,
        "type" => "LiveView"
      }

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, fn ->
        [lv_process]
      end)

      MockClient
      |> expect(:push_event!, fn ^root_socket_id, "found-node-element", event_payload ->
        assert event_payload["module"] == "LiveDebuggerTest.LiveView"
        assert event_payload["type"] == "LiveView"
        assert event_payload["id_key"] == "PID"
        assert event_payload["id_value"] == "0.123.0"
        :ok
      end)

      assert {:noreply, _} =
               ClientCommunicator.handle_info({"request-node-element", payload}, [])
    end

    test "handles LiveComponent request when component found", %{
      socket_id: socket_id,
      root_socket_id: root_socket_id,
      lv_process: lv_process
    } do
      cid = 1

      payload = %{
        "socket_id" => socket_id,
        "root_socket_id" => root_socket_id,
        "type" => "LiveComponent",
        "id" => Integer.to_string(cid)
      }

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, fn ->
        [lv_process]
      end)

      MockAPILiveViewDebug
      |> expect(:live_components, fn pid when pid == lv_process.pid ->
        {:ok, Fakes.live_components()}
      end)

      MockClient
      |> expect(:push_event!, fn ^root_socket_id, "found-node-element", event_payload ->
        assert event_payload["module"] == "LiveDebuggerDev.LiveComponents.ManyAssigns"
        assert event_payload["type"] == "LiveComponent"
        assert event_payload["id_key"] == "CID"
        assert event_payload["id_value"] == cid
        :ok
      end)

      assert {:noreply, _} =
               ClientCommunicator.handle_info({"request-node-element", payload}, [])
    end

    test "ignores LiveComponent request when component not found", %{
      socket_id: socket_id,
      root_socket_id: root_socket_id,
      lv_process: lv_process
    } do
      cid = 999

      payload = %{
        "socket_id" => socket_id,
        "root_socket_id" => root_socket_id,
        "type" => "LiveComponent",
        "id" => Integer.to_string(cid)
      }

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, fn ->
        [lv_process]
      end)

      MockAPILiveViewDebug
      |> expect(:live_components, fn pid when pid == lv_process.pid ->
        {:ok, Fakes.live_components()}
      end)

      # No expectation for push_event! since it should not be called when component not found

      assert {:noreply, _} =
               ClientCommunicator.handle_info({"request-node-element", payload}, [])
    end

    test "ignores request when process not found", %{
      socket_id: socket_id,
      root_socket_id: root_socket_id
    } do
      payload = %{
        "socket_id" => socket_id,
        "root_socket_id" => root_socket_id,
        "type" => "LiveView"
      }

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, fn ->
        []
      end)

      # No expectation for push_event! since it should not be called when process not found

      assert {:noreply, _} =
               ClientCommunicator.handle_info({"request-node-element", payload}, [])
    end
  end

  describe "handle_info/2 with other messages" do
    test "ignores other message types" do
      assert {:noreply, _} = ClientCommunicator.handle_info(:some_other_message, [])
      assert {:noreply, _} = ClientCommunicator.handle_info({"other-event", %{}}, [])
      assert {:noreply, _} = ClientCommunicator.handle_info({:some_atom, "data"}, [])
    end

    test "preserves state when handling other messages" do
      state = [custom: :data]
      assert {:noreply, ^state} = ClientCommunicator.handle_info(:some_message, state)
    end
  end
end
