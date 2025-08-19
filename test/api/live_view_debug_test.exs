defmodule LiveDebuggerRefactor.API.LiveViewDebugTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Structs.LvState
  alias LiveDebuggerRefactor.API.LiveViewDebug
  alias LiveDebuggerRefactor.MockAPILiveViewDebug
  alias LiveDebugger.Fakes

  setup :verify_on_exit!

  describe "liveview_state/1" do
    test "returns LiveView state for a given LiveView pid" do
      pid = :c.pid(0, 12, 0)

      socket = Fakes.socket()
      components = Fakes.live_components()

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, socket} end)
      |> expect(:live_components, fn ^pid -> {:ok, components} end)

      assert {:ok, %LvState{pid: ^pid, socket: ^socket, components: ^components}} =
               LiveViewDebug.liveview_state(pid)
    end

    test "return :error when Socket not available" do
      pid = :c.pid(0, 12, 0)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:error, :not_alive_or_not_a_liveview} end)

      assert {:error, :not_alive_or_not_a_liveview} =
               LiveViewDebug.liveview_state(pid)
    end

    test "return :error when LiveComponents not available" do
      pid = :c.pid(0, 12, 0)

      socket = Fakes.socket()

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, socket} end)
      |> expect(:live_components, fn ^pid -> {:error, :not_alive_or_not_a_liveview} end)

      assert {:error, :not_alive_or_not_a_liveview} =
               LiveViewDebug.liveview_state(pid)
    end
  end

  if not Code.ensure_loaded?(Phoenix.LiveView.Debug) do
    alias LiveDebuggerRefactor.MockAPIProcess

    describe "list_liveviews/0" do
      test "returns list of all active LiveView processes" do
        transport_pid = :c.pid(0, 11, 0)
        module = TestLV
        socket = Fakes.socket(transport_pid: transport_pid, view: module)
        topic = "lv:" <> socket.id
        lv_pid_1 = :c.pid(0, 12, 0)
        lv_pid_2 = :c.pid(0, 13, 0)
        non_lv_pid_1 = :c.pid(0, 14, 0)
        non_lv_pid_2 = :c.pid(0, 15, 0)

        MockAPIProcess
        |> expect(:list, fn -> [lv_pid_1, lv_pid_2, non_lv_pid_1, non_lv_pid_2] end)
        |> expect(:initial_call, 4, fn pid ->
          case pid do
            ^lv_pid_1 -> {:ok, {module, :mount, 3}}
            ^lv_pid_2 -> {:ok, {module, :mount, 3}}
            ^non_lv_pid_1 -> {:ok, {OtherModule, :init, 1}}
            ^non_lv_pid_2 -> {:ok, nil}
          end
        end)
        |> expect(:state, 2, fn pid ->
          case pid do
            ^lv_pid_1 -> {:ok, %{socket: socket, topic: topic}}
            ^lv_pid_2 -> {:error, :not_alive}
          end
        end)

        assert [
                 %{
                   pid: ^lv_pid_1,
                   view: ^module,
                   topic: ^topic,
                   transport_pid: ^transport_pid
                 }
               ] = LiveViewDebug.Impl.list_liveviews()
      end
    end

    describe "socket/1" do
      test "returns LiveView Socket for a given LiveView pid" do
        pid = :c.pid(0, 12, 0)

        socket = Fakes.socket()

        MockAPIProcess
        |> expect(:state, fn ^pid -> {:ok, %{socket: socket}} end)

        assert {:ok, ^socket} = LiveViewDebug.Impl.socket(pid)
      end

      test "returns :error if process is not a LiveView" do
        pid = :c.pid(0, 12, 0)

        MockAPIProcess
        |> expect(:state, fn ^pid -> {:ok, %{data: [], socket: %{c: 3}}} end)

        assert {:error, :not_alive_or_not_a_liveview} = LiveViewDebug.Impl.socket(pid)
      end

      test "returns :error if process is not alive" do
        pid = :c.pid(0, 12, 0)

        MockAPIProcess
        |> expect(:state, fn ^pid -> {:error, :not_alive} end)

        assert {:error, :not_alive_or_not_a_liveview} = LiveViewDebug.Impl.socket(pid)
      end
    end

    describe "live_components/1" do
      test "returns LiveComponents for a given LiveView pid" do
        pid = :c.pid(0, 12, 0)

        raw_components = Fakes.live_components_from_liveview_state()
        components = Fakes.live_components()

        MockAPIProcess
        |> expect(:state, fn ^pid -> {:ok, %{components: raw_components}} end)

        assert {:ok, ^components} = LiveViewDebug.Impl.live_components(pid)
      end

      test "returns :error if process is not a LiveView" do
        pid = :c.pid(0, 12, 0)

        MockAPIProcess
        |> expect(:state, fn ^pid -> {:ok, %{data: []}} end)

        assert {:error, :not_alive_or_not_a_liveview} = LiveViewDebug.Impl.live_components(pid)
      end

      test "returns :error if process is not alive" do
        pid = :c.pid(0, 12, 0)

        MockAPIProcess
        |> expect(:state, fn ^pid -> {:error, :not_alive} end)

        assert {:error, :not_alive_or_not_a_liveview} = LiveViewDebug.Impl.live_components(pid)
      end
    end
  end
end
