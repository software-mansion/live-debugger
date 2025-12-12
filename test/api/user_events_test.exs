defmodule LiveDebugger.API.UserEventsTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.API.UserEvents.Impl, as: UserEventsImpl
  alias LiveDebugger.Fakes
  alias Phoenix.LiveComponent.CID

  defmodule TestGenServer do
    @moduledoc false
    use GenServer

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    @impl true
    def init(opts) do
      {:ok, %{test_pid: Keyword.get(opts, :test_pid)}}
    end

    @impl true
    def handle_cast(message, state) do
      send(state.test_pid, {:cast_received, message})
      {:noreply, state}
    end

    @impl true
    def handle_call(message, _from, state) do
      send(state.test_pid, {:call_received, message})
      {:reply, {:ok, message}, state}
    end

    @impl true
    def handle_info(message, state) do
      send(state.test_pid, {:info_received, message})
      {:noreply, state}
    end
  end

  describe "send_info_message/2" do
    test "sends a message to the process" do
      {:ok, server_pid} = TestGenServer.start_link(test_pid: self())
      lv_process = Fakes.lv_process(pid: server_pid)
      payload = {:test_message, :hello}

      UserEventsImpl.send_info_message(lv_process, payload)

      assert_receive {:info_received, {:test_message, :hello}}
    end
  end

  describe "send_genserver_cast/2" do
    test "sends a GenServer cast to the LiveView process" do
      {:ok, server_pid} = TestGenServer.start_link(test_pid: self())
      lv_process = Fakes.lv_process(pid: server_pid)
      payload = {:some_cast, :data}

      result = UserEventsImpl.send_genserver_cast(lv_process, payload)

      assert result == :ok
      assert_receive {:cast_received, {:some_cast, :data}}
    end
  end

  describe "send_genserver_call/2" do
    test "sends a GenServer call to the LiveView process and returns response" do
      {:ok, server_pid} = TestGenServer.start_link(test_pid: self())
      lv_process = Fakes.lv_process(pid: server_pid)
      payload = {:some_call, :data}

      result = UserEventsImpl.send_genserver_call(lv_process, payload)

      assert result == {:ok, {:some_call, :data}}
      assert_receive {:call_received, {:some_call, :data}}
    end
  end

  describe "send_lv_event/4" do
    test "sends a Phoenix LiveView event without CID" do
      lv_process = Fakes.lv_process(pid: self(), socket_id: "phx-test-socket-123")
      event = "click"
      params = %{"id" => "button-1"}

      UserEventsImpl.send_lv_event(lv_process, nil, event, params)

      assert_receive %Phoenix.Socket.Message{
        topic: "lv:phx-test-socket-123",
        event: "event",
        payload: %{
          "event" => "click",
          "value" => %{"id" => "button-1"},
          "type" => "debug"
        }
      }
    end

    test "sends a Phoenix LiveView event with CID targeting a LiveComponent" do
      lv_process = Fakes.lv_process(pid: self(), socket_id: "phx-component-socket")
      cid = %CID{cid: 5}
      event = "submit"
      params = %{"form" => %{"name" => "John"}}

      UserEventsImpl.send_lv_event(lv_process, cid, event, params)

      assert_receive %Phoenix.Socket.Message{
        topic: "lv:phx-component-socket",
        event: "event",
        payload: %{
          "event" => "submit",
          "value" => %{"form" => %{"name" => "John"}},
          "type" => "debug",
          "cid" => 5
        }
      }
    end
  end

  describe "send_component_update/3" do
    test "calls Phoenix.LiveView.send_update with correct arguments" do
      {:ok, server_pid} = TestGenServer.start_link(test_pid: self())

      lv_process = Fakes.lv_process(pid: server_pid)
      cid = %CID{cid: 1}
      payload = %{some_assign: "value"}

      result = UserEventsImpl.send_component_update(lv_process, cid, payload)

      assert {:phoenix, :send_update, {^cid, ^payload}} = result
    end
  end
end
