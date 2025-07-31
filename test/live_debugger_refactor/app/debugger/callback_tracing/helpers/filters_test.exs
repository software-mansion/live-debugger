defmodule LiveDebuggerRefactor.CallbackTracing.Helpers.FiltersTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.CallbackTracing.Helpers.Filters, as: FiltersHelpers

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

  test "group_changed?/3 properly checks if group filters has changed" do
    params = %{
      "mount/3" => false,
      exec_time_min: 10,
      exec_time_max: 20,
      min_unit: "ms",
      max_unit: "ms"
    }

    filters = %{
      functions: %{
        "mount/3" => true
      },
      execution_time: %{
        exec_time_min: 10,
        exec_time_max: 20,
        min_unit: "ms",
        max_unit: "ms"
      }
    }

    assert FiltersHelpers.group_changed?(params, filters, :functions)
    refute FiltersHelpers.group_changed?(params, filters, :execution_time)
  end

  test "filters_changed?/2 properly checks if filters have changed" do
    params = %{
      "mount/3" => false,
      exec_time_min: 10,
      exec_time_max: 20,
      min_unit: "ms",
      max_unit: "ms"
    }

    filters = %{
      functions: %{
        "mount/3" => true
      },
      execution_time: %{
        exec_time_min: 10,
        exec_time_max: 20,
        min_unit: "ms",
        max_unit: "ms"
      }
    }

    assert FiltersHelpers.filters_changed?(params, filters)
  end
end
