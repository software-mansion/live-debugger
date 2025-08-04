defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.Helpers.FiltersTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.Helpers.Filters, as: FiltersHelpers

  describe "get_callbacks/1" do
    test "returns all callbacks when node_id is nil" do
      assert [
               "mount/3",
               "mount/1",
               "handle_params/3",
               "update/2",
               "update_many/1",
               "render/1",
               "handle_event/3",
               "handle_async/3",
               "handle_info/2",
               "handle_call/3",
               "handle_cast/2",
               "terminate/2"
             ] == FiltersHelpers.get_callbacks(nil)
    end

    test "returns proper callbacks based on node_id" do
      assert [
               "mount/1",
               "update/2",
               "update_many/1",
               "render/1",
               "handle_event/3",
               "handle_async/3"
             ] == FiltersHelpers.get_callbacks(%Phoenix.LiveComponent.CID{cid: 1})

      assert [
               "mount/3",
               "handle_params/3",
               "render/1",
               "handle_event/3",
               "handle_async/3",
               "handle_info/2",
               "handle_call/3",
               "handle_cast/2",
               "terminate/2"
             ] ==
               FiltersHelpers.get_callbacks(:c.pid(0, 123, 0))
    end
  end
end
