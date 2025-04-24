defmodule LiveDebugger.Services.LiveViewDiscoveryServiceTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.MockProcessService
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Fakes

  describe "debugged_lv_processes/0" do
    test "returns list of LvProcesses" do
      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)

      module = :"Elixir.SomeLiveView"

      MockProcessService
      |> expect(:list, fn -> [live_view_pid_1, live_view_pid_2] end)
      |> expect(:initial_call, 2, fn _ -> {module, :mount} end)
      |> expect(:state, fn ^live_view_pid_1 ->
        {:ok, Fakes.state(root_pid: live_view_pid_1, module: module)}
      end)
      |> expect(:state, fn ^live_view_pid_2 ->
        {:ok, Fakes.state(root_pid: live_view_pid_2, module: module)}
      end)

      assert [
               %LvProcess{pid: ^live_view_pid_1},
               %LvProcess{pid: ^live_view_pid_2}
             ] = LiveViewDiscoveryService.debugged_lv_processes()
    end

    test "doesn't return LiveDebugger LvProcesses" do
      live_view_pid = :c.pid(0, 0, 1)
      debugger_pid = :c.pid(0, 0, 2)

      module = :"Elixir.SomeLiveView"
      live_debugger_module = :"Elixir.LiveDebugger.Debugger"

      MockProcessService
      |> expect(:list, fn -> [live_view_pid, debugger_pid] end)
      |> expect(:initial_call, fn _ -> {module, :mount} end)
      |> expect(:initial_call, fn _ -> {live_debugger_module, :mount} end)
      |> expect(:state, fn ^live_view_pid ->
        {:ok, Fakes.state(root_pid: live_view_pid, module: module)}
      end)
      |> expect(:state, fn ^debugger_pid ->
        {:ok, Fakes.state(root_pid: debugger_pid, module: live_debugger_module)}
      end)

      assert [
               %LvProcess{pid: ^live_view_pid}
             ] = LiveViewDiscoveryService.debugged_lv_processes()
    end
  end

  test "debugger_lv_processes/0 returns only LiveDebugger LvProcesses" do
    live_debugger_pid = :c.pid(0, 0, 2)
    live_view_pid = :c.pid(0, 0, 1)

    live_debugger_module = :"Elixir.LiveDebugger.SomLiveView"
    live_view_module = :"Elixir.SomeLiveView"

    MockProcessService
    |> expect(:list, fn -> [live_debugger_pid, live_view_pid] end)
    |> expect(:initial_call, fn _ -> {live_debugger_module, :mount} end)
    |> expect(:initial_call, fn _ -> {live_view_module, :mount} end)
    |> expect(:state, fn ^live_debugger_pid ->
      {:ok, Fakes.state(root_pid: live_debugger_pid, module: live_debugger_module)}
    end)
    |> expect(:state, fn ^live_view_pid ->
      {:ok, Fakes.state(root_pid: live_view_pid, module: live_view_module)}
    end)

    assert [
             %LvProcess{pid: ^live_debugger_pid}
           ] = LiveViewDiscoveryService.debugger_lv_processes()
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

      MockProcessService
      |> expect(:list, fn -> [searched_live_view_pid, live_view_pid_1, live_view_pid_2] end)
      |> expect(:initial_call, fn _ -> {searched_module, :mount} end)
      |> expect(:initial_call, 2, fn _ -> {other_module, :mount} end)
      |> expect(:state, fn ^searched_live_view_pid ->
        {:ok,
         Fakes.state(
           root_pid: searched_live_view_pid,
           module: searched_module,
           socket_id: socket_id
         )}
      end)
      |> expect(:state, 2, fn live_view_pid ->
        {:ok,
         Fakes.state(root_pid: live_view_pid, module: other_module, socket_id: other_socket_id)}
      end)

      assert %LvProcess{pid: ^searched_live_view_pid} =
               LiveViewDiscoveryService.lv_process(socket_id)
    end

    test "returns nil if no LiveView process of given socket_id" do
      bad_socket_id = "phx-no-such-socket"
      module = :"Elixir.SomeLiveView"

      MockProcessService
      |> expect(:list, fn -> [:c.pid(0, 0, 0)] end)
      |> expect(:initial_call, fn _ -> {module, :mount} end)
      |> expect(:state, fn _ -> {:ok, Fakes.state()} end)

      assert LiveViewDiscoveryService.lv_process(bad_socket_id) == nil
    end

    test "returns nil if more than one LiveViewProcess of given socket_id found" do
      socket_id = "phx-GBsi_6M7paYhySQj"
      module = :"Elixir.SomeLiveView"

      MockProcessService
      |> expect(:list, fn -> [:c.pid(0, 0, 1), :c.pid(0, 0, 2)] end)
      |> expect(:initial_call, 2, fn _ -> {module, :mount} end)
      |> expect(:state, 2, fn _ -> {:ok, Fakes.state()} end)

      assert LiveViewDiscoveryService.lv_process(socket_id) == nil
    end
  end

  describe "children_lv_processes/1" do
    test "returns children LvProcesses of the given pid" do
      parent_pid = :c.pid(0, 0, 1)
      child_pid_1 = :c.pid(0, 1, 0)
      child_pid_2 = :c.pid(0, 2, 0)

      module = :"Elixir.SomeLiveView"

      MockProcessService
      |> stub(:list, fn -> [parent_pid, child_pid_1, child_pid_2] end)
      |> stub(:initial_call, fn _ -> {module, :mount} end)
      |> stub(:state, fn pid ->
        if pid == parent_pid do
          {:ok, Fakes.state(root_pid: parent_pid, module: module, parent_pid: nil)}
        else
          {:ok, Fakes.state(root_pid: parent_pid, module: module, parent_pid: parent_pid)}
        end
      end)

      assert [
               %LvProcess{pid: ^child_pid_1},
               %LvProcess{pid: ^child_pid_2}
             ] = LiveViewDiscoveryService.children_lv_processes(parent_pid)
    end

    test "returns children of children for given pid" do
      parent_pid = :c.pid(0, 0, 1)
      child_pid_1 = :c.pid(0, 1, 0)
      child_pid_2 = :c.pid(0, 2, 0)
      grandchild_pid = :c.pid(0, 3, 0)

      module = :"Elixir.SomeLiveView"

      MockProcessService
      |> stub(:list, fn -> [parent_pid, child_pid_1, child_pid_2, grandchild_pid] end)
      |> stub(:initial_call, fn _ -> {module, :mount} end)
      |> stub(:state, fn pid ->
        case pid do
          ^parent_pid ->
            {:ok, Fakes.state(root_pid: parent_pid, module: module, parent_pid: nil)}

          ^grandchild_pid ->
            {:ok, Fakes.state(root_pid: parent_pid, module: module, parent_pid: child_pid_1)}

          _ ->
            {:ok, Fakes.state(root_pid: parent_pid, module: module, parent_pid: parent_pid)}
        end
      end)

      children = LiveViewDiscoveryService.children_lv_processes(parent_pid)

      assert length(children) == 3

      for child <- children do
        assert Enum.find(children, &(&1.pid == child.pid)) != nil
      end
    end
  end
end
