defmodule LiveDebugger.Services.LiveViewDiscoveryServiceTest do
  use LiveDebugger.SystemCase

  import Mox

  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.MockProcessService

  describe "debugged_live_pids/0" do
    test "returns list of LiveView processes" do
      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)

      MockProcessService
      |> expect(:list, fn -> [live_view_pid_1, live_view_pid_2] end)
      |> expect(:initial_call, 2, fn _ -> {:"Elixir.SomeLiveView", :mount} end)

      assert LiveViewDiscoveryService.debugged_live_pids() == [live_view_pid_1, live_view_pid_2]
    end

    test "doesn't return LiveDebugger processes" do
      live_view_pid = :c.pid(0, 0, 1)
      debugger_pid = :c.pid(0, 0, 2)

      MockProcessService
      |> expect(:list, fn -> [live_view_pid, debugger_pid] end)
      |> expect(:initial_call, fn _ -> {:"Elixir.SomeLiveView", :mount} end)
      |> expect(:initial_call, fn _ -> {:"Elixir.LiveDebugger.Debugger", :mount} end)

      assert LiveViewDiscoveryService.debugged_live_pids() == [live_view_pid]
    end
  end

  describe "live_pid/1" do
    test "returns pid based on socket_id", %{pid: pid, socket_id: socket_id} do
      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)

      MockProcessService
      |> expect(:list, fn -> [pid, live_view_pid_1, live_view_pid_2] end)
      |> expect(:initial_call, fn _ -> {:"Elixir.SearchedLiveView", :mount} end)
      |> expect(:initial_call, 2, fn _ -> {:"Elixir.SomeLiveView", :mount} end)

      assert {^pid, _} = LiveViewDiscoveryService.live_pid(socket_id)
    end

    test "returns nil if no LiveView process of given socket_id", %{pid: pid} do
      bad_socket_id = "phx-no-such-socket"

      MockProcessService
      |> expect(:list, fn -> [pid] end)
      |> expect(:initial_call, fn _ -> {:"Elixir.SomeLiveView", :mount} end)

      assert LiveViewDiscoveryService.live_pid(bad_socket_id) == nil
    end
  end
end
