defmodule LiveDebugger.API.LiveViewDiscoveryTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.API.LiveViewDiscovery.Impl, as: LiveViewDiscoveryImpl
  alias LiveDebugger.MockAPILiveViewDebug
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Fakes

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

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn ->
        [
          Fakes.liveview(pid: searched_live_view_pid, view: searched_module),
          Fakes.liveview(pid: live_view_pid_1, view: other_module),
          Fakes.liveview(pid: live_view_pid_2, view: other_module)
        ]
      end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^searched_live_view_pid ->
        {:ok,
         Fakes.socket(root_pid: searched_live_view_pid, view: searched_module, id: socket_id)}
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

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn ->
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

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn ->
        [
          Fakes.liveview(pid: live_view_pid_1),
          Fakes.liveview(pid: live_view_pid_2)
        ]
      end)

      MockAPILiveViewDebug
      |> expect(:socket, 2, fn _ -> {:ok, Fakes.socket()} end)

      assert nil ==
               LiveViewDiscoveryImpl.lv_process(searched_live_view_pid)
    end

    test "returns nil if no LiveView process of given socket_id" do
      searched_socket_id = "phx-GBsi_6M7paYhySQj"

      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)
      other_socket_id = "phx-other-socket"

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn ->
        [
          Fakes.liveview(pid: live_view_pid_1),
          Fakes.liveview(pid: live_view_pid_2)
        ]
      end)

      MockAPILiveViewDebug
      |> expect(:socket, 2, fn _ -> {:ok, Fakes.socket(id: other_socket_id)} end)

      assert nil ==
               LiveViewDiscoveryImpl.lv_process(searched_socket_id)
    end
  end

  test "group_lv_processes/1 groups LvProcesses into proper map" do
    pid_1 = :c.pid(0, 0, 1)
    pid_2 = :c.pid(0, 0, 2)
    pid_3 = :c.pid(0, 0, 3)

    root_pid_1 = :c.pid(0, 1, 1)
    root_pid_2 = :c.pid(0, 1, 2)
    root_pid_3 = :c.pid(0, 1, 3)

    transport_pid_1 = :c.pid(0, 7, 1)
    transport_pid_2 = :c.pid(0, 7, 2)

    lv_process_1 = %LvProcess{
      pid: root_pid_1,
      root_pid: root_pid_1,
      parent_pid: nil,
      transport_pid: transport_pid_1
    }

    lv_process_2 = %LvProcess{
      pid: pid_1,
      root_pid: root_pid_1,
      parent_pid: root_pid_1,
      transport_pid: transport_pid_1
    }

    lv_process_3 = %LvProcess{
      pid: root_pid_2,
      root_pid: root_pid_2,
      parent_pid: nil,
      transport_pid: transport_pid_2
    }

    lv_process_4 = %LvProcess{
      pid: pid_2,
      root_pid: root_pid_2,
      parent_pid: root_pid_2,
      transport_pid: transport_pid_2
    }

    lv_process_5 = %LvProcess{
      pid: pid_3,
      root_pid: root_pid_2,
      parent_pid: pid_2,
      transport_pid: transport_pid_2
    }

    lv_process_6 = %LvProcess{
      pid: root_pid_3,
      root_pid: root_pid_3,
      parent_pid: nil,
      transport_pid: transport_pid_2
    }

    assert %{
             transport_pid_1 => %{
               lv_process_1 => %{lv_process_2 => nil}
             },
             transport_pid_2 => %{
               lv_process_3 => %{lv_process_4 => %{lv_process_5 => nil}},
               lv_process_6 => nil
             }
           } ==
             LiveViewDiscoveryImpl.group_lv_processes([
               lv_process_1,
               lv_process_2,
               lv_process_3,
               lv_process_4,
               lv_process_5,
               lv_process_6
             ])
  end

  test "lv_processes/0 returns all LiveView processes" do
    live_view_pid_1 = :c.pid(0, 0, 1)
    live_view_pid_2 = :c.pid(0, 0, 2)

    module = :"Elixir.SomeLiveView"

    MockAPILiveViewDebug
    |> stub(:list_liveviews, fn ->
      [
        Fakes.liveview(pid: live_view_pid_1, view: module),
        Fakes.liveview(pid: live_view_pid_2, view: module)
      ]
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

      MockAPILiveViewDebug
      |> stub(:list_liveviews, fn ->
        [
          Fakes.liveview(pid: parent_pid, view: module),
          Fakes.liveview(pid: child_pid_1, view: module),
          Fakes.liveview(pid: child_pid_2, view: module)
        ]
      end)

      MockAPILiveViewDebug
      |> stub(:socket, fn pid ->
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

      MockAPILiveViewDebug
      |> stub(:list_liveviews, fn ->
        [
          Fakes.liveview(pid: parent_pid, view: module),
          Fakes.liveview(pid: child_pid_1, view: module),
          Fakes.liveview(pid: child_pid_2, view: module),
          Fakes.liveview(pid: grandchild_pid, view: module)
        ]
      end)

      MockAPILiveViewDebug
      |> stub(:socket, fn pid ->
        case pid do
          ^parent_pid ->
            {:ok, Fakes.socket(root_pid: parent_pid, view: module, parent_pid: nil)}

          ^grandchild_pid ->
            {:ok, Fakes.socket(root_pid: parent_pid, view: module, parent_pid: child_pid_1)}

          _ ->
            {:ok, Fakes.socket(root_pid: parent_pid, view: module, parent_pid: parent_pid)}
        end
      end)

      children = LiveViewDiscoveryImpl.children_lv_processes(parent_pid)

      assert length(children) == 3

      for child <- children do
        assert Enum.find(children, &(&1.pid == child.pid)) != nil
      end
    end
  end

  describe "get_root_socket_id/1" do
    test "returns socket_id for a regular LvProcess" do
      pid = :c.pid(0, 11, 0)

      lv_process = %LvProcess{
        pid: pid,
        root_pid: pid,
        transport_pid: :c.pid(0, 12, 0),
        socket_id: "regular",
        embedded?: false,
        nested?: false
      }

      assert "regular" == LiveViewDiscoveryImpl.get_root_socket_id(lv_process)
    end

    test "returns root socket_id for an embedded LvProcess if a root exists with same transport_pid" do
      embedded_pid = :c.pid(0, 11, 0)
      root_pid = :c.pid(0, 12, 0)
      transport_pid = :c.pid(0, 13, 0)
      root_socket_id = "root_socket"

      embedded_lv_process =
        %LvProcess{
          pid: embedded_pid,
          transport_pid: transport_pid,
          socket_id: "embedded_socket",
          embedded?: true,
          nested?: false
        }

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn ->
        [Fakes.liveview(pid: root_pid), Fakes.liveview(pid: embedded_pid)]
      end)
      |> expect(:socket, 2, fn
        ^root_pid ->
          {:ok,
           Fakes.socket(
             id: root_socket_id,
             root_pid: root_pid,
             transport_pid: transport_pid,
             view: Test
           )}

        ^embedded_pid ->
          {:ok,
           Fakes.socket(
             id: embedded_lv_process.socket_id,
             root_pid: embedded_pid,
             transport_pid: transport_pid,
             embedded?: true,
             view: Test
           )}
      end)

      assert root_socket_id == LiveViewDiscoveryImpl.get_root_socket_id(embedded_lv_process)
    end

    test "returns its own socket_id for an embedded LvProcess if no root exists with same transport_pid" do
      pid = :c.pid(0, 11, 0)
      transport_pid = :c.pid(0, 12, 0)

      embedded_lv_process =
        %LvProcess{
          pid: pid,
          transport_pid: transport_pid,
          socket_id: "embedded_socket",
          embedded?: true,
          nested?: false
        }

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn -> [Fakes.liveview(pid: pid)] end)
      |> expect(:socket, fn
        ^pid ->
          {:ok,
           Fakes.socket(
             id: embedded_lv_process.socket_id,
             root_pid: pid,
             transport_pid: transport_pid,
             view: Test
           )}
      end)

      assert embedded_lv_process.socket_id ==
               LiveViewDiscoveryImpl.get_root_socket_id(embedded_lv_process)
    end

    test "returns root socket_id for a nested LvProcess with a regular root" do
      pid = :c.pid(0, 12, 0)
      root_pid = :c.pid(0, 11, 0)
      root_socket_id = "root_socket"

      nested_lv_process =
        %LvProcess{
          pid: pid,
          root_pid: root_pid,
          nested?: true,
          socket_id: "nested_socket"
        }

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn ->
        [Fakes.liveview(pid: pid), Fakes.liveview(pid: root_pid)]
      end)
      |> expect(:socket, 2, fn
        ^root_pid ->
          {:ok,
           Fakes.socket(
             id: root_socket_id,
             root_pid: root_pid,
             view: Test
           )}

        ^pid ->
          {:ok,
           Fakes.socket(
             id: nested_lv_process.socket_id,
             root_pid: root_pid,
             view: Test
           )}
      end)

      assert root_socket_id == LiveViewDiscoveryImpl.get_root_socket_id(nested_lv_process)
    end

    test "returns root socket_id for a nested LvProcess with an embedded root" do
      transport_pid = :c.pid(0, 15, 0)
      root_pid = :c.pid(0, 11, 0)
      embedded_pid = :c.pid(0, 12, 0)
      pid = :c.pid(0, 10, 0)
      root_socket_id = "root_socket"
      embedded_socket_id = "embedded_socket"

      nested_lv_process =
        %LvProcess{
          pid: pid,
          root_pid: embedded_pid,
          nested?: true,
          socket_id: "nested_socket"
        }

      MockAPILiveViewDebug
      |> expect(:list_liveviews, 2, fn ->
        [
          Fakes.liveview(pid: root_pid),
          Fakes.liveview(pid: embedded_pid),
          Fakes.liveview(pid: pid)
        ]
      end)
      |> expect(:socket, 6, fn
        ^root_pid ->
          {:ok,
           Fakes.socket(
             id: root_socket_id,
             root_pid: root_pid,
             transport_pid: transport_pid,
             view: Test
           )}

        ^embedded_pid ->
          {:ok,
           Fakes.socket(
             id: embedded_socket_id,
             root_pid: embedded_pid,
             transport_pid: transport_pid,
             embedded?: true,
             view: Test
           )}

        ^pid ->
          {:ok,
           Fakes.socket(
             id: nested_lv_process.socket_id,
             root_pid: embedded_pid,
             transport_pid: transport_pid,
             nested?: true,
             view: Test
           )}
      end)

      assert root_socket_id == LiveViewDiscoveryImpl.get_root_socket_id(nested_lv_process)
    end

    test "returns nil for a nested LvProcess if root_pid is not found" do
      root_pid = :c.pid(0, 11, 0)
      pid = :c.pid(0, 10, 0)

      nested_lv_process =
        %LvProcess{
          pid: pid,
          root_pid: root_pid,
          nested?: true,
          socket_id: "nested_socket"
        }

      MockAPILiveViewDebug
      |> expect(:list_liveviews, fn -> [Fakes.liveview(pid: pid)] end)
      |> expect(:socket, fn
        ^pid ->
          {:ok,
           Fakes.socket(
             id: nested_lv_process.socket_id,
             root_pid: root_pid,
             view: Test
           )}
      end)

      assert nil == LiveViewDiscoveryImpl.get_root_socket_id(nested_lv_process)
    end
  end
end
