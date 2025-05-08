defmodule LiveDebugger.Utils.CallbacksTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Utils.Callbacks, as: CallbackUtils

  test "live_view_callbacks/0" do
    assert [
             {:mount, 3},
             {:handle_params, 3},
             {:handle_info, 2},
             {:handle_call, 3},
             {:handle_cast, 2},
             {:terminate, 2},
             {:render, 1},
             {:handle_event, 3},
             {:handle_async, 3}
           ] = CallbackUtils.live_view_callbacks()
  end

  test "live_component_callbacks/0" do
    assert [
             {:mount, 1},
             {:update, 2},
             {:update_many, 1},
             {:render, 1},
             {:handle_event, 3},
             {:handle_async, 3}
           ] = CallbackUtils.live_component_callbacks()
  end

  describe "live_view_callbacks/1" do
    test "returns proper callbacks for LiveView module" do
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

    test "returns list of callbacks for multiple LiveView modules" do
      assert [
               {LiveDebuggerTest.TestView1, :mount, 3},
               {LiveDebuggerTest.TestView1, :handle_params, 3},
               {LiveDebuggerTest.TestView1, :handle_info, 2},
               {LiveDebuggerTest.TestView1, :handle_call, 3},
               {LiveDebuggerTest.TestView1, :handle_cast, 2},
               {LiveDebuggerTest.TestView1, :terminate, 2},
               {LiveDebuggerTest.TestView1, :render, 1},
               {LiveDebuggerTest.TestView1, :handle_event, 3},
               {LiveDebuggerTest.TestView1, :handle_async, 3},
               {LiveDebuggerTest.TestView2, :mount, 3},
               {LiveDebuggerTest.TestView2, :handle_params, 3},
               {LiveDebuggerTest.TestView2, :handle_info, 2},
               {LiveDebuggerTest.TestView2, :handle_call, 3},
               {LiveDebuggerTest.TestView2, :handle_cast, 2},
               {LiveDebuggerTest.TestView2, :terminate, 2},
               {LiveDebuggerTest.TestView2, :render, 1},
               {LiveDebuggerTest.TestView2, :handle_event, 3},
               {LiveDebuggerTest.TestView2, :handle_async, 3}
             ] =
               CallbackUtils.live_view_callbacks([
                 LiveDebuggerTest.TestView1,
                 LiveDebuggerTest.TestView2
               ])
    end
  end

  describe "live_component_callbacks/1" do
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

    test "returns list of callbacks for multiple LiveComponent modules" do
      assert [
               {LiveDebuggerTest.TestComponent1, :mount, 1},
               {LiveDebuggerTest.TestComponent1, :update, 2},
               {LiveDebuggerTest.TestComponent1, :update_many, 1},
               {LiveDebuggerTest.TestComponent1, :render, 1},
               {LiveDebuggerTest.TestComponent1, :handle_event, 3},
               {LiveDebuggerTest.TestComponent1, :handle_async, 3},
               {LiveDebuggerTest.TestComponent2, :mount, 1},
               {LiveDebuggerTest.TestComponent2, :update, 2},
               {LiveDebuggerTest.TestComponent2, :update_many, 1},
               {LiveDebuggerTest.TestComponent2, :render, 1},
               {LiveDebuggerTest.TestComponent2, :handle_event, 3},
               {LiveDebuggerTest.TestComponent2, :handle_async, 3}
             ] =
               CallbackUtils.live_component_callbacks([
                 LiveDebuggerTest.TestComponent1,
                 LiveDebuggerTest.TestComponent2
               ])
    end
  end

  test "callbacks_functions/1 returns names of all callbacks" do
    assert [
             :render,
             :handle_event,
             :handle_async,
             :mount,
             :handle_params,
             :handle_info,
             :handle_call,
             :handle_cast,
             :terminate,
             :update,
             :update_many
           ] = CallbackUtils.callbacks_functions()
  end
end
