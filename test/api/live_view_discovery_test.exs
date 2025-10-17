defmodule LiveDebugger.API.LiveViewDiscoveryTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.API.LiveViewDiscovery.Impl, as: LiveViewDiscoveryImpl
  alias LiveDebugger.Fakes
  alias LiveDebugger.MockAPILiveViewDebug
  alias LiveDebugger.Structs.LvProcess

  setup :verify_on_exit!

  describe "debugged_lv_processes/0" do
    test "returns list of LvProcesses" do
      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)

      module = :"Elixir.SomeLiveView"

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn ->
        [Fakes.liveview(pid: live_view_pid_1), Fakes.liveview(pid: live_view_pid_2)]
      end)
      |> expect(:socket, fn ^live_view_pid_1 ->
        {:ok, Fakes.socket(root_pid: live_view_pid_1, view: module)}
      end)
      |> expect(:socket, fn ^live_view_pid_2 ->
        {:ok, Fakes.socket(root_pid: live_view_pid_2, view: module)}
      end)

      assert [
               %LvProcess{pid: ^live_view_pid_1},
               %LvProcess{pid: ^live_view_pid_2}
             ] = LiveViewDiscoveryImpl.debugged_lv_processes()
    end

    test "doesn't return LiveDebugger LvProcesses" do
      live_view_pid = :c.pid(0, 0, 1)
      live_debugger_pid = :c.pid(0, 0, 2)

      live_view_module = :"Elixir.SomeLiveView"
      live_debugger_module = :"Elixir.LiveDebugger.App.Web.Debugger"

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn ->
        [
          Fakes.liveview(pid: live_view_pid, view: live_view_module),
          Fakes.liveview(pid: live_debugger_pid, view: live_debugger_module)
        ]
      end)
      |> expect(:socket, fn ^live_view_pid ->
        {:ok, Fakes.socket(root_pid: live_view_pid, view: live_view_module)}
      end)
      |> expect(:socket, fn ^live_debugger_pid ->
        {:ok, Fakes.socket(root_pid: live_debugger_pid, view: live_debugger_module)}
      end)

      assert [
               %LvProcess{
                 pid: ^live_view_pid,
                 module: ^live_view_module,
                 debugger?: false,
                 alive?: true
               }
             ] = LiveViewDiscoveryImpl.debugged_lv_processes()
    end
  end

  test "debugger_lv_processes/0 returns only LiveDebugger LvProcesses" do
    live_debugger_pid = :c.pid(0, 0, 2)
    live_view_pid = :c.pid(0, 0, 1)

    live_debugger_module = :"Elixir.LiveDebugger.App.Web.SomLiveView"
    live_view_module = :"Elixir.SomeLiveView"

    MockAPILiveViewDebug
    |> expect(:list_liveviews, fn ->
      [
        Fakes.liveview(pid: live_debugger_pid, view: live_debugger_module),
        Fakes.liveview(pid: live_view_pid, view: live_view_module)
      ]
    end)
    |> expect(:socket, fn ^live_debugger_pid ->
      {:ok, Fakes.socket(root_pid: live_debugger_pid, view: live_debugger_module)}
    end)
    |> expect(:socket, fn ^live_view_pid ->
      {:ok, Fakes.socket(root_pid: live_view_pid, view: live_view_module)}
    end)

    assert [
             %LvProcess{
               pid: ^live_debugger_pid,
               module: ^live_debugger_module,
               debugger?: true
             }
           ] = LiveViewDiscoveryImpl.debugger_lv_processes()
  end

  describe "lv_process/1" do
    test "returns LvProcess based on socket_id" do
      searched_live_view_pid = :c.pid(0, 1, 0)
      searched_module = :"Elixir.SearchedLiveView"
      socket_id = "phx-GBsi_6M7paYhySQj"

      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)
      other_module = :"Elixir.SomeLiveView"
      other_socket_id = "phx-other-socket"

      expect(MockAPILiveViewDebug, :list_liveviews, fn ->
        [
          Fakes.liveview(pid: searched_live_view_pid, view: searched_module),
          Fakes.liveview(pid: live_view_pid_1, view: other_module),
          Fakes.liveview(pid: live_view_pid_2, view: other_module)
        ]
      end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^searched_live_view_pid ->
        {:ok, Fakes.socket(root_pid: searched_live_view_pid, view: searched_module, id: socket_id)}
      end)
      |> expect(:socket, 2, fn live_view_pid ->
        {:ok, Fakes.socket(root_pid: live_view_pid, view: other_module, id: other_socket_id)}
      end)

      assert %LvProcess{
               pid: ^searched_live_view_pid,
               module: ^searched_module
             } = LiveViewDiscoveryImpl.lv_process(socket_id)
    end

    test "returns nil if no LiveView process of given socket_id" do
      bad_socket_id = "phx-no-such-socket"

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn -> [Fakes.liveview()] end)
      |> expect(:socket, fn _pid -> {:ok, Fakes.socket()} end)

      assert LiveViewDiscoveryImpl.lv_process(bad_socket_id) == nil
    end

    test "returns nil if more than one LiveViewProcess of given socket_id found" do
      socket = Fakes.socket()
      socket_id = socket.id

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn ->
        [Fakes.liveview(pid: :c.pid(0, 0, 1)), Fakes.liveview(pid: :c.pid(0, 0, 2))]
      end)
      |> expect(:socket, 2, fn _ -> {:ok, socket} end)

      assert LiveViewDiscoveryImpl.lv_process(socket_id) == nil
    end
  end

  describe "lv_process/2" do
    test "returns LvProcess based on given pid" do
      searched_live_view_pid = :c.pid(0, 1, 0)
      searched_module = SearchedLiveView

      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)
      other_module = SomeLiveView

      searched_live_view = Fakes.liveview(pid: searched_live_view_pid, view: searched_module)
      live_view_1 = Fakes.liveview(pid: live_view_pid_1, view: other_module)
      live_view_2 = Fakes.liveview(pid: live_view_pid_2, view: other_module)

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn -> [searched_live_view, live_view_1, live_view_2] end)
      |> expect(:socket, fn ^searched_live_view_pid ->
        {:ok, Fakes.socket(view: searched_module)}
      end)
      |> expect(:socket, 2, fn _pid ->
        {:ok, Fakes.socket(view: other_module)}
      end)

      assert %LvProcess{module: ^searched_module} =
               LiveViewDiscoveryImpl.lv_process(searched_live_view_pid)
    end

    test "returns LvProcess based on given socket_id" do
      searched_live_view_pid = :c.pid(0, 1, 0)
      searched_module = SearchedLiveView
      searched_socket_id = "phx-GBsi_6M7paYhySQj"

      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)
      other_module = :"Elixir.SomeLiveView"
      other_socket_id = "phx-other-socket"

      expect(MockAPILiveViewDebug, :list_liveviews, fn ->
        [
          Fakes.liveview(pid: searched_live_view_pid, view: searched_module),
          Fakes.liveview(pid: live_view_pid_1, view: other_module),
          Fakes.liveview(pid: live_view_pid_2, view: other_module)
        ]
      end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^searched_live_view_pid ->
        {:ok,
         Fakes.socket(
           view: searched_module,
           id: searched_socket_id
         )}
      end)
      |> expect(:socket, fn _pid ->
        {:ok,
         Fakes.socket(
           view: other_module,
           id: other_socket_id
         )}
      end)
      |> expect(:socket, fn _pid ->
        {:ok,
         Fakes.socket(
           view: other_module,
           id: other_socket_id
         )}
      end)

      assert %LvProcess{module: ^searched_module} =
               LiveViewDiscoveryImpl.lv_process(searched_socket_id)
    end

    test "returns nil if no LiveView process of given pid" do
      searched_live_view_pid = :c.pid(0, 1, 0)

      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)

      expect(MockAPILiveViewDebug, :list_liveviews, fn ->
        [Fakes.liveview(pid: live_view_pid_1), Fakes.liveview(pid: live_view_pid_2)]
      end)

      expect(MockAPILiveViewDebug, :socket, 2, fn _ -> {:ok, Fakes.socket()} end)

      assert nil ==
               LiveViewDiscoveryImpl.lv_process(searched_live_view_pid)
    end

    test "returns nil if no LiveView process of given socket_id" do
      searched_socket_id = "phx-GBsi_6M7paYhySQj"

      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)
      other_socket_id = "phx-other-socket"

      expect(MockAPILiveViewDebug, :list_liveviews, fn ->
        [Fakes.liveview(pid: live_view_pid_1), Fakes.liveview(pid: live_view_pid_2)]
      end)

      expect(MockAPILiveViewDebug, :socket, 2, fn _ -> {:ok, Fakes.socket(id: other_socket_id)} end)

      assert nil ==
               LiveViewDiscoveryImpl.lv_process(searched_socket_id)
    end
  end

  test "group_lv_processes/1 groups LvProcesses into proper map" do
    pid_1 = :c.pid(0, 0, 1)
    pid_2 = :c.pid(0, 0, 2)

    root_pid_1 = :c.pid(0, 1, 1)
    root_pid_2 = :c.pid(0, 1, 2)
    root_pid_3 = :c.pid(0, 1, 3)

    transport_pid_1 = :c.pid(0, 7, 1)
    transport_pid_2 = :c.pid(0, 7, 2)

    lv_process_1 = %LvProcess{
      pid: root_pid_1,
      root_pid: root_pid_1,
      transport_pid: transport_pid_1
    }

    lv_process_2 = %LvProcess{
      pid: pid_1,
      root_pid: root_pid_1,
      transport_pid: transport_pid_1
    }

    lv_process_3 = %LvProcess{
      pid: root_pid_2,
      root_pid: root_pid_2,
      transport_pid: transport_pid_2
    }

    lv_process_4 = %LvProcess{
      pid: pid_2,
      root_pid: root_pid_2,
      transport_pid: transport_pid_2
    }

    lv_process_5 = %LvProcess{
      pid: root_pid_3,
      root_pid: root_pid_3,
      transport_pid: transport_pid_2
    }

    assert %{
             transport_pid_1 => %{
               lv_process_1 => [lv_process_2]
             },
             transport_pid_2 => %{
               lv_process_3 => [lv_process_4],
               lv_process_5 => []
             }
           } ==
             LiveViewDiscoveryImpl.group_lv_processes([
               lv_process_1,
               lv_process_2,
               lv_process_3,
               lv_process_4,
               lv_process_5
             ])
  end

  test "lv_processes/0 returns all LiveView processes" do
    live_view_pid_1 = :c.pid(0, 0, 1)
    live_view_pid_2 = :c.pid(0, 0, 2)

    module = :"Elixir.SomeLiveView"

    stub(MockAPILiveViewDebug, :list_liveviews, fn ->
      [Fakes.liveview(pid: live_view_pid_1, view: module), Fakes.liveview(pid: live_view_pid_2, view: module)]
    end)

    MockAPILiveViewDebug
    |> expect(:socket, fn ^live_view_pid_1 ->
      {:ok, Fakes.socket(root_pid: live_view_pid_1, view: module)}
    end)
    |> expect(:socket, fn ^live_view_pid_2 ->
      {:ok, Fakes.socket(root_pid: live_view_pid_2, view: module)}
    end)

    assert [
             %LvProcess{pid: ^live_view_pid_1},
             %LvProcess{pid: ^live_view_pid_2}
           ] = LiveViewDiscoveryImpl.lv_processes()
  end

  describe "children_lv_processes/1" do
    test "returns children LvProcesses of the given pid" do
      parent_pid = :c.pid(0, 0, 1)
      child_pid_1 = :c.pid(0, 1, 0)
      child_pid_2 = :c.pid(0, 2, 0)

      module = :"Elixir.SomeLiveView"

      stub(MockAPILiveViewDebug, :list_liveviews, fn ->
        [
          Fakes.liveview(pid: parent_pid, view: module),
          Fakes.liveview(pid: child_pid_1, view: module),
          Fakes.liveview(pid: child_pid_2, view: module)
        ]
      end)

      stub(MockAPILiveViewDebug, :socket, fn pid ->
        if pid == parent_pid do
          {:ok, Fakes.socket(root_pid: parent_pid, view: module, parent_pid: nil)}
        else
          {:ok, Fakes.socket(root_pid: parent_pid, view: module, parent_pid: parent_pid)}
        end
      end)

      assert [
               %LvProcess{pid: ^child_pid_1},
               %LvProcess{pid: ^child_pid_2}
             ] = LiveViewDiscoveryImpl.children_lv_processes(parent_pid)
    end

    test "returns children of children for given pid" do
      parent_pid = :c.pid(0, 0, 1)
      child_pid_1 = :c.pid(0, 1, 0)
      child_pid_2 = :c.pid(0, 2, 0)
      grandchild_pid = :c.pid(0, 3, 0)

      module = :"Elixir.SomeLiveView"

      stub(MockAPILiveViewDebug, :list_liveviews, fn ->
        [
          Fakes.liveview(pid: parent_pid, view: module),
          Fakes.liveview(pid: child_pid_1, view: module),
          Fakes.liveview(pid: child_pid_2, view: module),
          Fakes.liveview(pid: grandchild_pid, view: module)
        ]
      end)

      stub(MockAPILiveViewDebug, :socket, fn pid ->
        case pid do
          ^parent_pid -> {:ok, Fakes.socket(root_pid: parent_pid, view: module, parent_pid: nil)}
          ^grandchild_pid -> {:ok, Fakes.socket(root_pid: parent_pid, view: module, parent_pid: child_pid_1)}
          _ -> {:ok, Fakes.socket(root_pid: parent_pid, view: module, parent_pid: parent_pid)}
        end
      end)

      children = LiveViewDiscoveryImpl.children_lv_processes(parent_pid)

      assert length(children) == 3

      for child <- children do
        assert Enum.find(children, &(&1.pid == child.pid)) != nil
      end
    end
  end
end
