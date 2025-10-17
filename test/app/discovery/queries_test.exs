defmodule LiveDebugger.App.Discovery.QueriesTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.App.Discovery.Queries, as: DiscoveryQueries
  alias LiveDebugger.MockAPILiveViewDiscovery
  alias LiveDebugger.Structs.LvProcess

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

      assert {:ok, %{grouped_lv_processes: ^grouped_lv_processes}} =
               DiscoveryQueries.fetch_grouped_lv_processes()
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

      assert {:ok, %{grouped_lv_processes: ^grouped_lv_processes}} =
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

      assert {:ok, %{grouped_lv_processes: ^grouped_lv_processes}} =
               DiscoveryQueries.fetch_grouped_lv_processes()
    end

    test "returns empty map when no active LiveViews" do
      MockAPILiveViewDiscovery
      |> expect(:debugged_lv_processes, 3, fn -> [] end)
      |> expect(:group_lv_processes, fn [] -> %{} end)

      assert {:ok, %{grouped_lv_processes: %{}}} =
               DiscoveryQueries.fetch_grouped_lv_processes()
    end
  end
end
