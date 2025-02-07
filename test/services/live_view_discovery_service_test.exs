defmodule LiveDebugger.Services.LiveViewDiscoveryServiceTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.MockProcessService
  alias LiveDebugger.Test.Fakes

  describe "debugged_live_pids/0" do
    test "returns list of LiveView processes" do
      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)

      MockProcessService
      |> expect(:list, fn -> [live_view_pid_1, live_view_pid_2] end)
      |> expect(:initial_call, 2, fn _ -> {:"Elixir.SomeLiveView", :mount} end)
      |> expect(:state, fn ^live_view_pid_1 -> {:ok, Fakes.state(root_pid: live_view_pid_1)} end)
      |> expect(:state, fn ^live_view_pid_2 -> {:ok, Fakes.state(root_pid: live_view_pid_2)} end)

      assert LiveViewDiscoveryService.debugged_live_pids() == [live_view_pid_1, live_view_pid_2]
    end

    test "doesn't return LiveDebugger processes" do
      live_view_pid = :c.pid(0, 0, 1)
      debugger_pid = :c.pid(0, 0, 2)

      MockProcessService
      |> expect(:list, fn -> [live_view_pid, debugger_pid] end)
      |> expect(:initial_call, fn _ -> {:"Elixir.SomeLiveView", :mount} end)
      |> expect(:initial_call, fn _ -> {:"Elixir.LiveDebugger.Debugger", :mount} end)
      |> expect(:state, fn ^live_view_pid -> {:ok, Fakes.state(root_pid: live_view_pid)} end)
      |> expect(:state, fn ^debugger_pid -> {:ok, Fakes.state(root_pid: debugger_pid)} end)

      assert LiveViewDiscoveryService.debugged_live_pids() == [live_view_pid]
    end
  end

  describe "live_pids/1" do
    test "returns pids of LiveView processes based on socket_id" do
      pid = :c.pid(0, 1, 0)
      socket_id = "phx-socket-id"
      live_view_pid_1 = :c.pid(0, 0, 1)
      live_view_pid_2 = :c.pid(0, 0, 2)

      MockProcessService
      |> expect(:list, fn -> [pid, live_view_pid_1, live_view_pid_2] end)
      |> expect(:initial_call, fn _ -> {:"Elixir.SearchedLiveView", :mount} end)
      |> expect(:initial_call, 2, fn _ -> {:"Elixir.SomeLiveView", :mount} end)
      |> expect(:state, fn ^pid -> {:ok, Fakes.state(root_pid: pid, socket_id: socket_id)} end)
      |> expect(:state, 2, fn _ -> {:ok, Fakes.state(socket_id: "phx-no-such-socket")} end)

      assert LiveViewDiscoveryService.live_pids(socket_id) == [pid]
    end

    test "returns empty list if no LiveView process of given socket_id" do
      pid = :c.pid(0, 0, 0)
      bad_socket_id = "phx-no-such-socket"

      MockProcessService
      |> expect(:list, fn -> [pid] end)
      |> expect(:initial_call, fn _ -> {:"Elixir.SomeLiveView", :mount} end)
      |> expect(:state, fn ^pid -> {:ok, Fakes.state(socket_id: "phx-socket-id")} end)

      assert LiveViewDiscoveryService.live_pids(bad_socket_id) == []
    end
  end
end
