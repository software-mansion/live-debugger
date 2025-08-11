defmodule LiveDebuggerRefactor.App.Debugger.Queries.LvProcessTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  alias LiveDebuggerRefactor.Structs.LvState
  alias LiveDebuggerRefactor.App.Debugger.Queries.LvProcess, as: LvProcessQueries
  alias LiveDebuggerRefactor.MockAPIStatesStorage
  alias LiveDebuggerRefactor.MockAPILiveViewDebug
  alias LiveDebuggerRefactor.Fakes
  alias LiveDebuggerRefactor.Structs.LvProcess

  describe "parent_lv_process/1" do
    test "uses StatesStorage to fetch the parent lv process" do
      pid = :c.pid(0, 0, 1)
      parent_pid = :c.pid(0, 0, 2)

      lv_process = %LvProcess{
        pid: pid,
        parent_pid: parent_pid
      }

      lv_state = %LvState{
        pid: pid,
        socket: Fakes.socket(parent_pid: parent_pid),
        components: []
      }

      MockAPIStatesStorage
      |> expect(:get!, fn ^parent_pid -> lv_state end)

      assert %LvProcess{pid: ^parent_pid} = LvProcessQueries.parent_lv_process(lv_process)
    end

    test "uses LiveViewDebug to fetch the parent lv process when not in StatesStorage" do
      pid = :c.pid(0, 0, 1)
      parent_pid = :c.pid(0, 0, 2)

      lv_process = %LvProcess{
        pid: pid,
        parent_pid: parent_pid
      }

      MockAPIStatesStorage
      |> expect(:get!, fn ^parent_pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^parent_pid -> {:ok, Fakes.socket()} end)

      assert %LvProcess{pid: ^parent_pid} = LvProcessQueries.parent_lv_process(lv_process)
    end

    test "returns nil when the parent lv process is not found" do
      parent_pid = :c.pid(0, 0, 2)

      lv_process = %LvProcess{
        pid: :c.pid(0, 0, 1),
        parent_pid: parent_pid
      }

      MockAPIStatesStorage
      |> expect(:get!, fn ^parent_pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^parent_pid -> {:error, :not_found} end)

      assert nil == LvProcessQueries.parent_lv_process(lv_process)
    end
  end

  describe "fetch_with_retries/1" do
    test "returns nil after 3 tries" do
      pid = :c.pid(0, 0, 1)

      MockAPIStatesStorage
      |> expect(:get!, 3, fn ^pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, 3, fn ^pid -> {:error, :not_found} end)

      assert nil == LvProcessQueries.fetch_with_retries(pid)
    end

    test "returns LvProcess when found" do
      pid = :c.pid(0, 0, 1)

      MockAPIStatesStorage
      |> expect(:get!, fn ^pid -> %LvState{pid: pid, socket: Fakes.socket(), components: []} end)

      assert %LvProcess{pid: ^pid} = LvProcessQueries.fetch_with_retries(pid)
    end

    test "uses LiveViewDebug when not in StatesStorage" do
      pid = :c.pid(0, 0, 1)

      MockAPIStatesStorage
      |> expect(:get!, fn ^pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, Fakes.socket()} end)

      assert %LvProcess{pid: ^pid} = LvProcessQueries.fetch_with_retries(pid)
    end
  end
end
