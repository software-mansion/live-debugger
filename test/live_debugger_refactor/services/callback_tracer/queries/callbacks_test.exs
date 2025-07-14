defmodule LiveDebuggerRefactor.Services.CallbackTracer.Queries.CallbacksTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Services.CallbackTracer.Queries.Callbacks
  alias LiveDebuggerRefactor.MockAPIModule

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
  end
end
