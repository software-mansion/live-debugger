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

  describe "get_lv_process/1" do
    test "returns LvProcess when found" do
      pid = :c.pid(0, 0, 1)

      MockAPIStatesStorage
      |> expect(:get!, fn ^pid -> %LvState{pid: pid, socket: Fakes.socket(), components: []} end)

      assert %LvProcess{pid: ^pid} = LvProcessQueries.get_lv_process(pid)
    end

    test "uses LiveViewDebug when not in StatesStorage" do
      pid = :c.pid(0, 0, 1)

      MockAPIStatesStorage
      |> expect(:get!, fn ^pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid -> {:ok, Fakes.socket()} end)

      assert %LvProcess{pid: ^pid} = LvProcessQueries.get_lv_process(pid)
    end
  end
end
