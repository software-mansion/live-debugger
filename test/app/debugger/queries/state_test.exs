defmodule LiveDebugger.App.Debugger.Queries.StateTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.App.Debugger.Queries.State, as: StateQueries
  alias LiveDebugger.Fakes
  alias LiveDebugger.MockAPILiveViewDebug
  alias LiveDebugger.MockAPIStatesStorage
  alias LiveDebugger.Structs.LvState

  setup :verify_on_exit!

  describe "get_lv_state/1" do
    test "returns the LV state when it's in the StatesStorage" do
      pid = :c.pid(0, 0, 1)
      state = %LvState{pid: pid}

      expect(MockAPIStatesStorage, :get!, fn ^pid -> state end)
      assert {:ok, ^state} = StateQueries.get_lv_state(pid)
    end

    test "uses LiveViewDebug when not in StatesStorage" do
      pid = :c.pid(0, 0, 1)
      socket = Fakes.socket()
      components = Fakes.live_components()

      expect(MockAPIStatesStorage, :get!, fn ^pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, socket} end)
      |> expect(:live_components, fn ^pid -> {:ok, components} end)

      assert {:ok, %LvState{pid: ^pid, socket: ^socket, components: ^components}} =
               StateQueries.get_lv_state(pid)
    end
  end

  describe "get_socket/1" do
    test "returns the socket when it's in the StatesStorage" do
      pid = :c.pid(0, 0, 1)
      socket = Fakes.socket()

      expect(MockAPIStatesStorage, :get!, fn ^pid -> %LvState{pid: pid, socket: socket} end)
      assert {:ok, ^socket} = StateQueries.get_socket(pid)
    end

    test "uses LiveViewDebug when not in StatesStorage" do
      pid = :c.pid(0, 0, 1)
      socket = Fakes.socket()

      expect(MockAPIStatesStorage, :get!, fn ^pid -> nil end)
      expect(MockAPILiveViewDebug, :socket, fn ^pid -> {:ok, socket} end)
      assert {:ok, ^socket} = StateQueries.get_socket(pid)
    end
  end
end
