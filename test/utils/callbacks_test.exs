defmodule LiveDebugger.Utils.CallbacksTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils

  describe "tracing_callbacks/1" do
    test "returns proper callbacks for LiveView" do
      live_modules = %{
        live_views: [LiveDebuggerTest.TestView],
        live_components: []
      }

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
             ] = CallbackUtils.tracing_callbacks(live_modules)
    end

    test "returns proper callbacks for LiveComponent" do
      live_modules = %{
        live_views: [],
        live_components: [LiveDebuggerTest.TestComponent]
      }

      assert [
               {LiveDebuggerTest.TestComponent, :mount, 1},
               {LiveDebuggerTest.TestComponent, :update, 2},
               {LiveDebuggerTest.TestComponent, :update_many, 1},
               {LiveDebuggerTest.TestComponent, :render, 1},
               {LiveDebuggerTest.TestComponent, :handle_event, 3},
               {LiveDebuggerTest.TestComponent, :handle_async, 3}
             ] = CallbackUtils.tracing_callbacks(live_modules)
    end

    test "returns concatenated callbacks when both LiveViews and LiveComponents are present" do
      live_modules = %{
        live_views: [LiveDebuggerTest.TestView],
        live_components: [LiveDebuggerTest.TestComponent]
      }

      assert [
               {LiveDebuggerTest.TestView, :mount, 3},
               {LiveDebuggerTest.TestView, :handle_params, 3},
               {LiveDebuggerTest.TestView, :handle_info, 2},
               {LiveDebuggerTest.TestView, :handle_call, 3},
               {LiveDebuggerTest.TestView, :handle_cast, 2},
               {LiveDebuggerTest.TestView, :terminate, 2},
               {LiveDebuggerTest.TestView, :render, 1},
               {LiveDebuggerTest.TestView, :handle_event, 3},
               {LiveDebuggerTest.TestView, :handle_async, 3},
               {LiveDebuggerTest.TestComponent, :mount, 1},
               {LiveDebuggerTest.TestComponent, :update, 2},
               {LiveDebuggerTest.TestComponent, :update_many, 1},
               {LiveDebuggerTest.TestComponent, :render, 1},
               {LiveDebuggerTest.TestComponent, :handle_event, 3},
               {LiveDebuggerTest.TestComponent, :handle_async, 3}
             ] = CallbackUtils.tracing_callbacks(live_modules)
    end
  end
end
