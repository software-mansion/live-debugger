defmodule LiveDebugger.App.Discovery.ActionsTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.Services.GarbageCollector.Events.TableTrimmed
  alias LiveDebugger.App.Discovery.Actions, as: DiscoveryActions
  alias LiveDebugger.MockAPIStatesStorage
  alias LiveDebugger.MockBus

  describe "remove_lv_process_state!/1" do
    test "deletes single state" do
      pid = :c.pid(0, 11, 0)

      MockAPIStatesStorage
      |> expect(:delete!, fn ^pid -> :ok end)
      |> expect(:get_all_states, fn -> [] end)

      MockBus
      |> expect(:broadcast_event!, fn %TableTrimmed{} -> :ok end)

      DiscoveryActions.remove_lv_process_state!(pid)
    end

    test "deletes state and all nested LiveView states" do
      pid1 = :c.pid(0, 11, 0)
      pid2 = :c.pid(0, 21, 0)
      pid3 = :c.pid(0, 31, 0)
      pid4 = :c.pid(0, 41, 0)

      MockAPIStatesStorage
      |> expect(:delete!, fn ^pid1 -> :ok end)
      |> expect(:get_all_states, fn ->
        [
          {pid2, %LvState{socket: %{root_pid: pid1}}},
          {pid3, %LvState{socket: %{root_pid: pid3}}},
          {pid4, %LvState{socket: %{root_pid: pid3}}}
        ]
      end)
      |> expect(:delete!, fn ^pid2 -> :ok end)

      MockBus
      |> expect(:broadcast_event!, fn %TableTrimmed{} -> :ok end)

      DiscoveryActions.remove_lv_process_state!(pid1)
    end
  end
end
