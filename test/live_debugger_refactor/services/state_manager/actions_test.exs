defmodule LiveDebuggerRefactor.Services.StateManager.ActionsTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Services.StateManager.Actions, as: StateManagerActions
  alias LiveDebuggerRefactor.Fakes
  alias LiveDebuggerRefactor.Structs.LvState
  alias LiveDebuggerRefactor.MockAPILiveViewDebug
  alias LiveDebuggerRefactor.MockAPIStatesStorage

  setup :verify_on_exit!

  describe "save_state!/1" do
    test "saves state when process is alive" do
      pid = :c.pid(0, 1, 0)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:ok, Fakes.socket()}
      end)
      |> expect(:live_components, fn ^pid ->
        {:ok, Fakes.live_components()}
      end)

      MockAPIStatesStorage
      |> expect(:save!, fn %LvState{pid: ^pid} ->
        true
      end)

      assert :ok = StateManagerActions.save_state!(pid)
    end
  end
end
