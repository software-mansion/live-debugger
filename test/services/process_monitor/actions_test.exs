defmodule LiveDebugger.Services.ProcessMonitor.ActionsTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.MockAPILiveViewDebug
  alias LiveDebugger.Services.ProcessMonitor.Actions, as: ProcessMonitorActions

  alias LiveDebugger.MockBus
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentDeleted
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentCreated

  setup :verify_on_exit!

  test "register_component_create/3" do
    pid = self()
    cid = %Phoenix.LiveComponent.CID{cid: 1}
    state = %{pid => MapSet.new()}

    MockBus
    |> expect(:broadcast_event!, fn %LiveComponentCreated{cid: ^cid}, ^pid -> :ok end)

    new_state = ProcessMonitorActions.register_component_created!(state, pid, cid)

    assert new_state == %{pid => MapSet.new([cid])}
  end

  test "register_component_deleted/3" do
    pid = self()
    cid = %Phoenix.LiveComponent.CID{cid: 1}
    state = %{pid => MapSet.new([cid])}

    MockBus
    |> expect(:broadcast_event!, fn %LiveComponentDeleted{cid: ^cid}, ^pid -> :ok end)

    new_state = ProcessMonitorActions.register_component_deleted!(state, pid, cid)

    assert new_state == %{pid => MapSet.new([])}
  end

  test "register_live_view_born/2" do
    pid = self()
    transport_pid = :c.pid(0, 12, 0)
    state = %{}

    MockBus
    |> expect(:broadcast_event!, fn %LiveViewBorn{pid: ^pid} -> :ok end)

    MockAPILiveViewDebug
    |> expect(:live_components, fn ^pid -> {:ok, [%{cid: 1}, %{cid: 2}]} end)

    new_state = ProcessMonitorActions.register_live_view_born!(state, pid, transport_pid)

    assert new_state == %{
             pid =>
               MapSet.new([
                 %Phoenix.LiveComponent.CID{cid: 1},
                 %Phoenix.LiveComponent.CID{cid: 2}
               ])
           }
  end

  test "register_live_view_died/2" do
    pid = self()
    state = %{pid => MapSet.new()}

    MockBus
    |> expect(:broadcast_event!, fn %LiveViewDied{pid: ^pid} -> :ok end)

    new_state = ProcessMonitorActions.register_live_view_died!(state, pid)

    assert new_state == %{}
  end
end
