defmodule LiveDebuggerRefactor.Services.SuccessorDiscoverer.GenServers.SuccessorDiscovererTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Services.SuccessorDiscoverer.GenServers.SuccessorDiscoverer
  alias LiveDebuggerRefactor.Services.SuccessorDiscoverer.GenServers.SuccessorDiscoverer.State
  alias LiveDebuggerRefactor.Services.SuccessorDiscoverer.Events.SuccessorFound
  alias LiveDebuggerRefactor.Services.SuccessorDiscoverer.Events.SuccessorNotFound
  alias LiveDebuggerRefactor.App.Events.FindSuccessor

  alias LiveDebuggerRefactor.Structs.LvProcess

  alias LiveDebuggerRefactor.MockBus
  alias LiveDebuggerRefactor.MockClient
  alias LiveDebuggerRefactor.MockAPILiveViewDiscovery

  setup :verify_on_exit!

  describe "init/1" do
    test "listens to bus and client events" do
      expect(MockBus, :receive_events, fn -> :ok end)
      expect(MockClient, :receive_events, fn -> :ok end)

      assert {:ok, %{window_to_socket: %{}, socket_to_window: %{}}} = SuccessorDiscoverer.init([])
    end
  end

  describe "handle_info/2 with \"window-initialized\" event" do
    test "updates state correctly" do
      state = %State{}
      event = {"window-initialized", %{"window_id" => "uuid1", "socket_id" => "phx-123"}}

      assert {:noreply,
              %State{
                window_to_socket: %{"uuid1" => "phx-123"},
                socket_to_window: %{"phx-123" => "uuid1"}
              }} = SuccessorDiscoverer.handle_info(event, state)
    end

    test "ignores events with invalid payload" do
      state = %State{}
      event = {"window-initialized", %{"socket_id" => "phx-123"}}

      assert {:noreply, state} = SuccessorDiscoverer.handle_info(event, state)
      assert state.window_to_socket == %{}
      assert state.socket_to_window == %{}
    end
  end

  describe "handle_info/2 with %FindSuccessor{} event" do
    test "finds successor" do
      state = %State{}
      event = %FindSuccessor{lv_process: %LvProcess{socket_id: "phx-123"}}

      assert {:noreply, _state} = SuccessorDiscoverer.handle_info(event, state)
      assert_receive {:find_successor, %LvProcess{socket_id: "phx-123"}, 0}
    end
  end

  describe "handle_info/2 with :find_successor message" do
    # This a case when transport pid was not changed e.g. when user used LiveNavigation
    # WebSocket connection in such case is not closed => transport pid is not changed
    test "finds successor using transport pid" do
      socket_id = "phx-123"
      window_id = "uuid1"
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: socket_id,
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      state = %State{
        window_to_socket: %{window_id => socket_id},
        socket_to_window: %{socket_id => window_id}
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
            socket_id: "phx-456",
            transport_pid: :c.pid(0, 10, 0),
            nested?: false,
            embedded?: false
          }
        ]
      end)

      expect(MockBus, :broadcast_event!, fn event ->
        assert event == %SuccessorFound{
                 old_socket_id: socket_id,
                 new_socket_id: "phx-successor"
               }

        :ok
      end)

      event = {:find_successor, lv_process, 0}

      assert {:noreply, state} = SuccessorDiscoverer.handle_info(event, state)
      assert state.window_to_socket == %{window_id => socket_id}
      assert state.socket_to_window == %{}
    end

    # This is a case when page was reloaded => WS connection was closed => transport pid was changed
    # In such case, when connection is re-established, client sends event with association {window_id, new_socket_id}
    # In window_to_socket map record is replaced with new socket_id (window_id is still the same, socket_id changes because new LiveView was created)
    # In socket_to_window map new record is created telling that given LiveView can be found in the following window
    # When we find successor, we can remove old record from socket_to_window map since LiveView with this socket_id is dead
    test "finds successor using state" do
      socket_id = "phx-123"
      window_id = "uuid1"
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: socket_id,
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      state = %State{
        window_to_socket: %{window_id => "phx-successor"},
        socket_to_window: %{socket_id => window_id, "phx-successor" => window_id}
      }

      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        [
          %LvProcess{
            socket_id: "phx-456",
            transport_pid: :c.pid(0, 10, 0),
            nested?: false,
            embedded?: false
          },
          %LvProcess{
            socket_id: "phx-789",
            transport_pid: :c.pid(0, 11, 0),
            nested?: false,
            embedded?: false
          }
        ]
      end)

      expect(MockBus, :broadcast_event!, fn event ->
        assert event == %SuccessorFound{
                 old_socket_id: socket_id,
                 new_socket_id: "phx-successor"
               }

        :ok
      end)

      event = {:find_successor, lv_process, 0}

      assert {:noreply, state} = SuccessorDiscoverer.handle_info(event, state)
      assert state.window_to_socket == %{window_id => "phx-successor"}
      assert state.socket_to_window == %{"phx-successor" => window_id}
    end

    test "reattempts to find successor when attempt is less than 3" do
      socket_id = "phx-123"
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: socket_id,
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        []
      end)

      event = {:find_successor, lv_process, 0}

      state = %State{
        window_to_socket: %{"uuid1" => "phx-456"},
        socket_to_window: %{"phx-456" => "uuid1"}
      }

      assert {:noreply, _state} = SuccessorDiscoverer.handle_info(event, state)
      assert_receive({:find_successor, %LvProcess{socket_id: ^socket_id}, 1}, 300)
    end

    test "stops reattempting to find successor when attempt is 3" do
      socket_id = "phx-123"
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: socket_id,
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      expect(MockBus, :broadcast_event!, fn event ->
        assert event == %SuccessorNotFound{socket_id: socket_id}

        :ok
      end)

      event = {:find_successor, lv_process, 3}

      state = %State{
        window_to_socket: %{"uuid1" => "phx-456"},
        socket_to_window: %{"phx-456" => "uuid1"}
      }

      assert {:noreply, _state} = SuccessorDiscoverer.handle_info(event, state)
    end
  end
end
