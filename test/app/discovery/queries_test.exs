defmodule LiveDebugger.App.Discovery.QueriesTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Fakes
  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Discovery.Queries, as: DiscoveryQueries
  alias LiveDebugger.MockAPILiveViewDiscovery
  alias LiveDebugger.MockAPIStatesStorage

  describe "fetch_grouped_lv_processes/1" do
    test "returns LiveView processes using api" do
      lv_process =
        %LvProcess{
          pid: :c.pid(0, 1, 0),
          transport_pid: :c.pid(0, 12, 0),
          module: LiveDebuggerTest.DummyLiveView
        }

      grouped_lv_processes = %{lv_process.transport_pid => %{lv_process => []}}

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, fn -> [lv_process] end)
      |> expect(:group_lv_processes, fn [^lv_process] -> grouped_lv_processes end)

      assert {^grouped_lv_processes, 1} = DiscoveryQueries.fetch_grouped_lv_processes()
    end

    test "returns LiveView processes with transport_pid" do
      transport_pid = :c.pid(0, 12, 0)

      lv_process =
        %LvProcess{
          pid: :c.pid(0, 1, 0),
          transport_pid: transport_pid,
          module: LiveDebuggerTest.DummyLiveView
        }

      grouped_lv_processes = %{transport_pid => %{lv_process => []}}

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, fn ^transport_pid -> [lv_process] end)
      |> expect(:group_lv_processes, fn [^lv_process] -> grouped_lv_processes end)

      assert {^grouped_lv_processes, 1} =
               DiscoveryQueries.fetch_grouped_lv_processes(transport_pid)
    end

    test "returns LiveView processes after few backoffs" do
      lv_process =
        %LvProcess{
          pid: :c.pid(0, 1, 0),
          transport_pid: :c.pid(0, 12, 0),
          module: LiveDebuggerTest.DummyLiveView
        }

      grouped_lv_processes = %{lv_process.transport_pid => %{lv_process => []}}

      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, 2, fn -> [] end)
      |> expect(:debugged_lv_processes, fn -> [lv_process] end)
      |> expect(:group_lv_processes, fn [^lv_process] -> grouped_lv_processes end)

      assert {^grouped_lv_processes, 1} = DiscoveryQueries.fetch_grouped_lv_processes()
    end

    test "returns empty map when no active LiveViews" do
      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, 3, fn -> [] end)
      |> expect(:group_lv_processes, fn [] -> %{} end)

      assert {%{}, 0} = DiscoveryQueries.fetch_grouped_lv_processes()
    end
  end

  describe "fetch_dead_grouped_lv_processes/0" do
    test "returns empty map when no dead LiveViews" do
      pid = spawn(fn -> Process.sleep(:infinity) end)

      MockAPIStatesStorage
      |> expect(:get_all_states, fn -> [{pid, %LvState{pid: pid, socket: %{}}}] end)

      MockAPILiveViewDiscovery
      |> expect(:group_lv_processes, fn [] -> %{} end)

      assert {%{}, 0} = DiscoveryQueries.fetch_dead_grouped_lv_processes()

      Process.exit(pid, :kill)
    end

    test "returns dead LiveView processes using api" do
      pid = spawn(fn -> :ok end)
      transport_pid = :c.pid(0, 12, 0)

      socket =
        Fakes.socket(pid: pid, transport_pid: transport_pid, nested?: false, view: SomeLiveView)

      MockAPIStatesStorage
      |> expect(:get_all_states, fn -> [{pid, %LvState{pid: pid, socket: socket}}] end)

      MockAPILiveViewDiscovery
      |> expect(:group_lv_processes, fn
        [
          %LvProcess{
            pid: ^pid,
            transport_pid: ^transport_pid,
            alive?: false
          } = lv_process
        ] ->
          %{transport_pid => %{lv_process => []}}
      end)

      assert {%{
                transport_pid => %{
                  %LvProcess{
                    pid: pid,
                    transport_pid: transport_pid,
                    alive?: false,
                    socket_id: socket.id,
                    root_pid: pid,
                    parent_pid: nil,
                    module: socket.view,
                    nested?: false,
                    embedded?: false,
                    debugger?: false
                  } => []
                }
              }, 1} == DiscoveryQueries.fetch_dead_grouped_lv_processes()
    end
  end
end
