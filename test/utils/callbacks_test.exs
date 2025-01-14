defmodule LiveDebugger.Utils.CallbacksTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils

  describe "tracing_callbacks/1" do
    test "returns proper callbacks for LiveView" do
      assert [
               {LiveDebuggerTest.TestView, :mount, 3},
               {LiveDebuggerTest.TestView, :handle_params, 3},
               {LiveDebuggerTest.TestView, :handle_info, 2},
               {LiveDebuggerTest.TestView, :handle_call, 3},
               {LiveDebuggerTest.TestView, :handle_cast, 2},
               {LiveDebuggerTest.TestView, :terminate, 2},
               {LiveDebuggerTest.TestView, :render, 1},
               {LiveDebuggerTest.TestView, :handle_event, 3},
               {LiveDebuggerTest.TestView, :handle_async, 3}
             ] = CallbackUtils.live_view_callbacks(LiveDebuggerTest.TestView)
    end

    test "returns proper callbacks for LiveComponent" do
      assert [
               {LiveDebuggerTest.TestComponent, :mount, 1},
               {LiveDebuggerTest.TestComponent, :update, 2},
               {LiveDebuggerTest.TestComponent, :update_many, 1},
               {LiveDebuggerTest.TestComponent, :render, 1},
               {LiveDebuggerTest.TestComponent, :handle_event, 3},
               {LiveDebuggerTest.TestComponent, :handle_async, 3}
             ] = CallbackUtils.live_component_callbacks(LiveDebuggerTest.TestComponent)
    end
  end
end
