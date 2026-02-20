defmodule LiveDebugger.Services.CallbackTracer.Queries.CallbacksTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.CallbackTracer.Queries.Callbacks
  alias LiveDebugger.MockAPIModule

  describe "all_callbacks/0" do
    test "returns a list of all callbacks" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule", ~c"/path", true},
          {~c"Test.LiveComponentModule", ~c"/path", true}
        ]
      end)
      |> stub(:loaded?, fn module ->
        case module do
          :"Test.LiveViewModule" -> true
          :"Test.LiveComponentModule" -> true
        end
      end)
      |> stub(:live_module?, fn _module -> true end)
      |> stub(:behaviours, fn module ->
        case module do
          :"Test.LiveViewModule" -> [Phoenix.LiveView]
          :"Test.LiveComponentModule" -> [Phoenix.LiveComponent]
        end
      end)

      assert Callbacks.all_callbacks() == [
               {:"Test.LiveViewModule", :mount, 3},
               {:"Test.LiveViewModule", :handle_params, 3},
               {:"Test.LiveViewModule", :render, 1},
               {:"Test.LiveViewModule", :handle_event, 3},
               {:"Test.LiveViewModule", :handle_async, 3},
               {:"Test.LiveViewModule", :handle_info, 2},
               {:"Test.LiveViewModule", :handle_call, 3},
               {:"Test.LiveViewModule", :handle_cast, 2},
               {:"Test.LiveViewModule", :terminate, 2},
               {:"Test.LiveComponentModule", :mount, 1},
               {:"Test.LiveComponentModule", :update, 2},
               {:"Test.LiveComponentModule", :update_many, 1},
               {:"Test.LiveComponentModule", :render, 1},
               {:"Test.LiveComponentModule", :handle_event, 3},
               {:"Test.LiveComponentModule", :handle_async, 3}
             ]
    end

    test "returns empty list when no modules are available" do
      MockAPIModule
      |> expect(:all, fn -> [] end)

      assert Callbacks.all_callbacks() == []
    end

    test "filters out debugger modules" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"LiveDebugger.TestModule", ~c"/path", true},
          {~c"LiveDebugger.App.Web.TestModule", ~c"/path", true},
          {~c"Elixir.LiveDebugger.TestModule", ~c"/path", true},
          {~c"Elixir.LiveDebugger.App.Web.TestModule", ~c"/path", true}
        ]
      end)
      |> stub(:loaded?, fn _module -> true end)
      |> stub(:live_module?, fn _module -> true end)
      |> stub(:behaviours, fn _module -> [Phoenix.LiveView] end)

      assert Callbacks.all_callbacks() == []
    end

    test "filters out unloaded modules" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule", ~c"/path", true},
          {~c"Test.LiveComponentModule", ~c"/path", false}
        ]
      end)
      |> stub(:loaded?, fn module ->
        case module do
          :"Test.LiveViewModule" -> true
          :"Test.LiveComponentModule" -> false
        end
      end)
      |> stub(:live_module?, fn _module -> true end)
      |> stub(:behaviours, fn module ->
        case module do
          :"Test.LiveViewModule" -> [Phoenix.LiveView]
          :"Test.LiveComponentModule" -> [Phoenix.LiveComponent]
        end
      end)

      assert Callbacks.all_callbacks() == [
               {:"Test.LiveViewModule", :mount, 3},
               {:"Test.LiveViewModule", :handle_params, 3},
               {:"Test.LiveViewModule", :render, 1},
               {:"Test.LiveViewModule", :handle_event, 3},
               {:"Test.LiveViewModule", :handle_async, 3},
               {:"Test.LiveViewModule", :handle_info, 2},
               {:"Test.LiveViewModule", :handle_call, 3},
               {:"Test.LiveViewModule", :handle_cast, 2},
               {:"Test.LiveViewModule", :terminate, 2}
             ]
    end

    test "ignores regular modules without LiveView or LiveComponent behaviours" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.RegularModule", ~c"/path", true}
        ]
      end)
      |> stub(:loaded?, fn _module -> true end)
      |> stub(:live_module?, fn _module -> false end)
      |> stub(:behaviours, fn _module -> [] end)

      assert Callbacks.all_callbacks() == []
    end

    test "handles modules with multiple behaviours correctly" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule", ~c"/path", true}
        ]
      end)
      |> stub(:loaded?, fn _module -> true end)
      |> stub(:live_module?, fn _module -> true end)
      |> stub(:behaviours, fn module ->
        case module do
          :"Test.LiveViewModule" -> [Phoenix.LiveView, :SomeOtherBehaviour]
        end
      end)

      assert Callbacks.all_callbacks() == [
               {:"Test.LiveViewModule", :mount, 3},
               {:"Test.LiveViewModule", :handle_params, 3},
               {:"Test.LiveViewModule", :render, 1},
               {:"Test.LiveViewModule", :handle_event, 3},
               {:"Test.LiveViewModule", :handle_async, 3},
               {:"Test.LiveViewModule", :handle_info, 2},
               {:"Test.LiveViewModule", :handle_call, 3},
               {:"Test.LiveViewModule", :handle_cast, 2},
               {:"Test.LiveViewModule", :terminate, 2}
             ]
    end

    test "handles only LiveView modules" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule1", ~c"/path", true},
          {~c"Test.LiveViewModule2", ~c"/path", true}
        ]
      end)
      |> stub(:loaded?, fn _module -> true end)
      |> stub(:live_module?, fn _module -> true end)
      |> stub(:behaviours, fn module ->
        case module do
          :"Test.LiveViewModule1" -> [Phoenix.LiveView]
          :"Test.LiveViewModule2" -> [Phoenix.LiveView]
        end
      end)

      assert Callbacks.all_callbacks() == [
               {:"Test.LiveViewModule1", :mount, 3},
               {:"Test.LiveViewModule1", :handle_params, 3},
               {:"Test.LiveViewModule1", :render, 1},
               {:"Test.LiveViewModule1", :handle_event, 3},
               {:"Test.LiveViewModule1", :handle_async, 3},
               {:"Test.LiveViewModule1", :handle_info, 2},
               {:"Test.LiveViewModule1", :handle_call, 3},
               {:"Test.LiveViewModule1", :handle_cast, 2},
               {:"Test.LiveViewModule1", :terminate, 2},
               {:"Test.LiveViewModule2", :mount, 3},
               {:"Test.LiveViewModule2", :handle_params, 3},
               {:"Test.LiveViewModule2", :render, 1},
               {:"Test.LiveViewModule2", :handle_event, 3},
               {:"Test.LiveViewModule2", :handle_async, 3},
               {:"Test.LiveViewModule2", :handle_info, 2},
               {:"Test.LiveViewModule2", :handle_call, 3},
               {:"Test.LiveViewModule2", :handle_cast, 2},
               {:"Test.LiveViewModule2", :terminate, 2}
             ]
    end

    test "handles only LiveComponent modules" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveComponentModule1", ~c"/path", true},
          {~c"Test.LiveComponentModule2", ~c"/path", true}
        ]
      end)
      |> stub(:loaded?, fn _module -> true end)
      |> stub(:live_module?, fn _module -> true end)
      |> stub(:behaviours, fn module ->
        case module do
          :"Test.LiveComponentModule1" -> [Phoenix.LiveComponent]
          :"Test.LiveComponentModule2" -> [Phoenix.LiveComponent]
        end
      end)

      assert Callbacks.all_callbacks() == [
               {:"Test.LiveComponentModule1", :mount, 1},
               {:"Test.LiveComponentModule1", :update, 2},
               {:"Test.LiveComponentModule1", :update_many, 1},
               {:"Test.LiveComponentModule1", :render, 1},
               {:"Test.LiveComponentModule1", :handle_event, 3},
               {:"Test.LiveComponentModule1", :handle_async, 3},
               {:"Test.LiveComponentModule2", :mount, 1},
               {:"Test.LiveComponentModule2", :update, 2},
               {:"Test.LiveComponentModule2", :update_many, 1},
               {:"Test.LiveComponentModule2", :render, 1},
               {:"Test.LiveComponentModule2", :handle_event, 3},
               {:"Test.LiveComponentModule2", :handle_async, 3}
             ]
    end

    test "handles mixed modules with some unloaded" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule", ~c"/path", true},
          {~c"Test.LiveComponentModule", ~c"/path", false},
          {~c"Test.RegularModule", ~c"/path", true}
        ]
      end)
      |> stub(:loaded?, fn module ->
        case module do
          :"Test.LiveViewModule" -> true
          :"Test.LiveComponentModule" -> false
          :"Test.RegularModule" -> true
        end
      end)
      |> stub(:live_module?, fn module ->
        case module do
          :"Test.LiveViewModule" -> true
          :"Test.LiveComponentModule" -> true
          :"Test.RegularModule" -> false
        end
      end)
      |> stub(:behaviours, fn module ->
        case module do
          :"Test.LiveViewModule" -> [Phoenix.LiveView]
          :"Test.LiveComponentModule" -> [Phoenix.LiveComponent]
          :"Test.RegularModule" -> []
        end
      end)

      assert Callbacks.all_callbacks() == [
               {:"Test.LiveViewModule", :mount, 3},
               {:"Test.LiveViewModule", :handle_params, 3},
               {:"Test.LiveViewModule", :render, 1},
               {:"Test.LiveViewModule", :handle_event, 3},
               {:"Test.LiveViewModule", :handle_async, 3},
               {:"Test.LiveViewModule", :handle_info, 2},
               {:"Test.LiveViewModule", :handle_call, 3},
               {:"Test.LiveViewModule", :handle_cast, 2},
               {:"Test.LiveViewModule", :terminate, 2}
             ]
    end

    test "ignores not loaded modules" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule", ~c"/path", true},
          {~c"Test.LiveComponentModule", ~c"/path", true}
        ]
      end)
      |> stub(:loaded?, fn module ->
        case module do
          :"Test.LiveViewModule" -> true
          :"Test.LiveComponentModule" -> false
        end
      end)
      |> stub(:live_module?, fn _module -> true end)
      |> stub(:behaviours, fn module ->
        case module do
          :"Test.LiveViewModule" -> [Phoenix.LiveView]
          :"Test.LiveComponentModule" -> [Phoenix.LiveComponent]
        end
      end)

      assert Callbacks.all_callbacks() == [
               {:"Test.LiveViewModule", :mount, 3},
               {:"Test.LiveViewModule", :handle_params, 3},
               {:"Test.LiveViewModule", :render, 1},
               {:"Test.LiveViewModule", :handle_event, 3},
               {:"Test.LiveViewModule", :handle_async, 3},
               {:"Test.LiveViewModule", :handle_info, 2},
               {:"Test.LiveViewModule", :handle_call, 3},
               {:"Test.LiveViewModule", :handle_cast, 2},
               {:"Test.LiveViewModule", :terminate, 2}
             ]
    end
  end

  describe "all_callbacks/1" do
    test "returns LiveView callbacks for a LiveView module" do
      MockAPIModule
      |> stub(:behaviours, fn :"Test.LiveViewModule" -> [Phoenix.LiveView] end)

      assert Callbacks.all_callbacks(:"Test.LiveViewModule") == [
               {:"Test.LiveViewModule", :mount, 3},
               {:"Test.LiveViewModule", :handle_params, 3},
               {:"Test.LiveViewModule", :render, 1},
               {:"Test.LiveViewModule", :handle_event, 3},
               {:"Test.LiveViewModule", :handle_async, 3},
               {:"Test.LiveViewModule", :handle_info, 2},
               {:"Test.LiveViewModule", :handle_call, 3},
               {:"Test.LiveViewModule", :handle_cast, 2},
               {:"Test.LiveViewModule", :terminate, 2}
             ]
    end

    test "returns LiveComponent callbacks for a LiveComponent module" do
      MockAPIModule
      |> stub(:behaviours, fn :"Test.LiveComponentModule" -> [Phoenix.LiveComponent] end)

      assert Callbacks.all_callbacks(:"Test.LiveComponentModule") == [
               {:"Test.LiveComponentModule", :mount, 1},
               {:"Test.LiveComponentModule", :update, 2},
               {:"Test.LiveComponentModule", :update_many, 1},
               {:"Test.LiveComponentModule", :render, 1},
               {:"Test.LiveComponentModule", :handle_event, 3},
               {:"Test.LiveComponentModule", :handle_async, 3}
             ]
    end

    test "returns error for a module without LiveView or LiveComponent behaviour" do
      MockAPIModule
      |> stub(:behaviours, fn :"Test.RegularModule" -> [] end)

      assert Callbacks.all_callbacks(:"Test.RegularModule") ==
               {:error, "Module Test.RegularModule is not a LiveView or LiveComponent"}
    end

    test "returns error for a module with other behaviours" do
      MockAPIModule
      |> stub(:behaviours, fn :"Test.GenServerModule" -> [GenServer] end)

      assert Callbacks.all_callbacks(:"Test.GenServerModule") ==
               {:error, "Module Test.GenServerModule is not a LiveView or LiveComponent"}
    end
  end
end
