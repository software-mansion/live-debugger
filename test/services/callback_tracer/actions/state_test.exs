defmodule LiveDebugger.Services.CallbackTracer.Actions.StateTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.CallbackTracer.Actions.State, as: StateActions
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged
  alias LiveDebugger.Fakes
  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.MockAPILiveViewDebug
  alias LiveDebugger.MockAPIStatesStorage
  alias LiveDebugger.MockBus

  setup :verify_on_exit!

  describe "maybe_save_state!/1" do
    test "does nothing when trace is not a state changing trace" do
      trace = %LiveDebugger.Structs.Trace{
        id: 1,
        module: TestModule,
        function: :handle_event,
        pid: :c.pid(0, 1, 0),
        type: :call
      }

      assert :ok = StateActions.maybe_save_state!(trace)
    end

    test "saves state and sends event when process is alive" do
      pid = :c.pid(0, 1, 0)

      trace = %LiveDebugger.Structs.Trace{
        id: 1,
        module: TestModule,
        function: :render,
        pid: :c.pid(0, 1, 0),
        type: :return_from
      }

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

      MockBus
      |> expect(:broadcast_state!, fn %StateChanged{pid: ^pid}, ^pid ->
        :ok
      end)

      assert :ok = StateActions.maybe_save_state!(trace)
    end

    test "returns error when process is not alive" do
      pid = :c.pid(0, 1, 0)

      trace = %LiveDebugger.Structs.Trace{
        id: 1,
        module: TestModule,
        function: :render,
        pid: :c.pid(0, 1, 0),
        type: :return_from
      }

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:error, :not_found}
      end)

      assert {:error, :not_found} = StateActions.maybe_save_state!(trace)
    end
  end
end
