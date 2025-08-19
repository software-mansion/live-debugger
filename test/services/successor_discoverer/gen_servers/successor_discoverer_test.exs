defmodule LiveDebugger.Services.SuccessorDiscoverer.GenServers.SuccessorDiscovererTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.SuccessorDiscoverer.GenServers.SuccessorDiscoverer
  alias LiveDebugger.Services.SuccessorDiscoverer.GenServers.SuccessorDiscoverer.State
  alias LiveDebugger.Services.SuccessorDiscoverer.Events.SuccessorFound
  alias LiveDebugger.Services.SuccessorDiscoverer.Events.SuccessorNotFound
  alias LiveDebugger.App.Events.FindSuccessor

  alias LiveDebugger.Structs.LvProcess

  alias LiveDebugger.MockBus
  alias LiveDebugger.MockClient
  alias LiveDebugger.MockAPILiveViewDiscovery

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
    # This is a case when transport pid was not changed e.g. when user used LiveNavigation
    # WebSocket connection in such case is not closed => transport pid is not changed
    test "finds successor using transport pid" do
      socket_id = "phx-123"
      window_id = "uuid1"
      transport_pid = :c.pid(0, 123, 0)

      lv_process = %LvProcess{
        socket_id: socket_id,
        pid: :c.pid(0, 999, 0),
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
            pid: :c.pid(0, 888, 0),
            transport_pid: transport_pid,
            nested?: false,
            embedded?: false
          },
          %LvProcess{
            socket_id: "phx-456",
            pid: :c.pid(0, 777, 0),
            transport_pid: :c.pid(0, 10, 0),
            nested?: false,
            embedded?: false
          }
        ]
      end)

      expect(MockBus, :broadcast_event!, fn event ->
        assert event == %SuccessorFound{
                 old_socket_id: socket_id,
                 new_lv_process: %LvProcess{
                   socket_id: "phx-successor",
                   pid: :c.pid(0, 888, 0),
                   transport_pid: transport_pid,
                   nested?: false,
                   embedded?: false
                 }
               }

        :ok
      end)

      event = {:find_successor, lv_process, 0}

      assert {:noreply, state} = SuccessorDiscoverer.handle_info(event, state)
      assert state.window_to_socket == %{window_id => socket_id}
      assert state.socket_to_window == %{socket_id => window_id}
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
        pid: :c.pid(0, 999, 0),
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
            pid: :c.pid(0, 555, 0),
            transport_pid: :c.pid(0, 10, 0),
            nested?: false,
            embedded?: false
          },
          %LvProcess{
            socket_id: "phx-789",
            pid: :c.pid(0, 666, 0),
            transport_pid: :c.pid(0, 11, 0),
            nested?: false,
            embedded?: false
          },
          %LvProcess{
            socket_id: "phx-successor",
            pid: :c.pid(0, 777, 0),
            transport_pid: :c.pid(0, 12, 0),
            nested?: false,
            embedded?: false
          }
        ]
      end)

      expect(MockBus, :broadcast_event!, fn event ->
        assert event == %SuccessorFound{
                 old_socket_id: socket_id,
                 new_lv_process: %LvProcess{
                   socket_id: "phx-successor",
                   pid: :c.pid(0, 777, 0),
                   transport_pid: :c.pid(0, 12, 0),
                   nested?: false,
                   embedded?: false
                 }
               }

        :ok
      end)

      event = {:find_successor, lv_process, 0}

      assert {:noreply, state} = SuccessorDiscoverer.handle_info(event, state)
      assert state.window_to_socket == %{window_id => "phx-successor"}
      assert state.socket_to_window == %{socket_id => window_id, "phx-successor" => window_id}
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
      assert_receive({:find_successor, %LvProcess{socket_id: ^socket_id}, 1}, 500)
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

    test "reattempts to find successor when found process has same pid" do
      socket_id = "phx-123"
      transport_pid = :c.pid(0, 123, 0)
      same_pid = :c.pid(0, 999, 0)

      lv_process = %LvProcess{
        socket_id: socket_id,
        pid: same_pid,
        transport_pid: transport_pid,
        nested?: false,
        embedded?: false
      }

      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        [
          %LvProcess{
            socket_id: "phx-different-socket",
            pid: same_pid,
            transport_pid: transport_pid,
            nested?: false,
            embedded?: false
          }
        ]
      end)

      event = {:find_successor, lv_process, 0}

      state = %State{
        window_to_socket: %{"uuid1" => socket_id},
        socket_to_window: %{socket_id => "uuid1"}
      }

      assert {:noreply, _state} = SuccessorDiscoverer.handle_info(event, state)
      assert_receive({:find_successor, %LvProcess{socket_id: ^socket_id}, 1}, 500)
    end
  end

  describe "handle_info/2 with combination of messages" do
    test "handles reload scenario" do
      # Start with initial state
      expect(MockBus, :receive_events, fn -> :ok end)
      expect(MockClient, :receive_events, fn -> :ok end)

      {:ok, state} = SuccessorDiscoverer.init([])

      # Step 1: Window gets initialized
      {:noreply, state} =
        SuccessorDiscoverer.handle_info(
          {"window-initialized", %{"window_id" => "window-1", "socket_id" => "socket-1"}},
          state
        )

      assert state.window_to_socket == %{"window-1" => "socket-1"}
      assert state.socket_to_window == %{"socket-1" => "window-1"}

      # Step 2: Page reloads, new socket is created for same window
      {:noreply, state} =
        SuccessorDiscoverer.handle_info(
          {"window-initialized", %{"window_id" => "window-1", "socket_id" => "socket-2"}},
          state
        )

      assert state.window_to_socket == %{"window-1" => "socket-2"}
      assert state.socket_to_window == %{"socket-1" => "window-1", "socket-2" => "window-1"}

      # Step 3: Try to find successor for old socket
      lv_process = %LvProcess{
        socket_id: "socket-1",
        pid: :c.pid(0, 999, 0),
        transport_pid: :c.pid(0, 123, 0),
        nested?: false,
        embedded?: false
      }

      # Mock API to return no processes with matching transport pid (so it falls back to state-based lookup)
      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        [
          %LvProcess{
            socket_id: "socket-2",
            pid: :c.pid(0, 888, 0),
            transport_pid: :c.pid(0, 456, 0),
            nested?: false,
            embedded?: false
          }
        ]
      end)

      # Expect successor found event
      expect(MockBus, :broadcast_event!, fn event ->
        assert event == %SuccessorFound{
                 old_socket_id: "socket-1",
                 new_lv_process: %LvProcess{
                   socket_id: "socket-2",
                   pid: :c.pid(0, 888, 0),
                   transport_pid: :c.pid(0, 456, 0),
                   nested?: false,
                   embedded?: false
                 }
               }

        :ok
      end)

      # Send FindSuccessor event
      {:noreply, state} =
        SuccessorDiscoverer.handle_info(%FindSuccessor{lv_process: lv_process}, state)

      assert_receive {:find_successor, %LvProcess{socket_id: "socket-1"}, 0}

      # Step 4: Find the successor
      {:noreply, state} =
        SuccessorDiscoverer.handle_info({:find_successor, lv_process, 0}, state)

      # Verify old socket was not removed from state
      assert state.window_to_socket == %{"window-1" => "socket-2"}
      assert state.socket_to_window == %{"socket-1" => "window-1", "socket-2" => "window-1"}
    end

    test "handles server down scenario" do
      # Start with initial state
      expect(MockBus, :receive_events, fn -> :ok end)
      expect(MockClient, :receive_events, fn -> :ok end)

      {:ok, state} = SuccessorDiscoverer.init([])

      # Step 1: Window gets initialized
      {:noreply, state} =
        SuccessorDiscoverer.handle_info(
          {"window-initialized", %{"window_id" => "window-1", "socket_id" => "socket-1"}},
          state
        )

      assert state.window_to_socket == %{"window-1" => "socket-1"}
      assert state.socket_to_window == %{"socket-1" => "window-1"}

      # Step 2: Server is down - try to find successor for socket-1 (but no successor exists yet)
      lv_process = %LvProcess{
        socket_id: "socket-1",
        pid: :c.pid(0, 999, 0),
        transport_pid: :c.pid(0, 123, 0),
        nested?: false,
        embedded?: false
      }

      # Mock API to return no processes
      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn -> [] end)

      # Send FindSuccessor event
      {:noreply, state} =
        SuccessorDiscoverer.handle_info(%FindSuccessor{lv_process: lv_process}, state)

      assert_receive {:find_successor, %LvProcess{socket_id: "socket-1"}, 0}

      # Step 3: Process the retry message (should fail again)
      {:noreply, state} =
        SuccessorDiscoverer.handle_info({:find_successor, lv_process, 0}, state)

      # State should remain unchanged since no successor was found
      assert state.window_to_socket == %{"window-1" => "socket-1"}
      assert state.socket_to_window == %{"socket-1" => "window-1"}

      # Step 4: Server is up again, socket reconnects
      {:noreply, state} =
        SuccessorDiscoverer.handle_info(
          {"window-initialized", %{"window_id" => "window-1", "socket_id" => "socket-2"}},
          state
        )

      assert state.window_to_socket == %{"window-1" => "socket-2"}
      assert state.socket_to_window == %{"socket-1" => "window-1", "socket-2" => "window-1"}

      # Step 5: Try to find successor again (should succeed now)
      lv_process_2 = %LvProcess{
        socket_id: "socket-1",
        pid: :c.pid(0, 999, 0),
        transport_pid: :c.pid(0, 123, 0),
        nested?: false,
        embedded?: false
      }

      # Mock API to return no processes with matching transport pid (so it falls back to state-based lookup)
      expect(MockAPILiveViewDiscovery, :debugged_lv_processes, fn ->
        [
          %LvProcess{
            socket_id: "socket-2",
            pid: :c.pid(0, 888, 0),
            transport_pid: :c.pid(0, 456, 0),
            nested?: false,
            embedded?: false
          }
        ]
      end)

      # Expect successor found event
      expect(MockBus, :broadcast_event!, fn event ->
        assert event == %SuccessorFound{
                 old_socket_id: "socket-1",
                 new_lv_process: %LvProcess{
                   socket_id: "socket-2",
                   pid: :c.pid(0, 888, 0),
                   transport_pid: :c.pid(0, 456, 0),
                   nested?: false,
                   embedded?: false
                 }
               }

        :ok
      end)

      # Send FindSuccessor event again
      {:noreply, state} =
        SuccessorDiscoverer.handle_info(%FindSuccessor{lv_process: lv_process_2}, state)

      assert_receive {:find_successor, %LvProcess{socket_id: "socket-1"}, 0}

      # Step 6: Process the find_successor message (should succeed)
      {:noreply, state} =
        SuccessorDiscoverer.handle_info({:find_successor, lv_process_2, 0}, state)

      # Verify old socket was not removed from state
      assert state.window_to_socket == %{"window-1" => "socket-2"}
      assert state.socket_to_window == %{"socket-1" => "window-1", "socket-2" => "window-1"}
    end
  end
end
