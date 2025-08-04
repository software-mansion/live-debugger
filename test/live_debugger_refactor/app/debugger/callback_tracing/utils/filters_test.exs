defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Utils.FiltersTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.App.Debugger.CallbackTracing.Utils.Filters, as: FiltersUtils
  alias LiveDebuggerRefactor.Utils.Callbacks, as: CallbacksUtils

  describe "node_callbacks/1" do
    test "returns all callbacks when node_id is nil" do
      assert FiltersUtils.node_callbacks(nil) == CallbacksUtils.all_callbacks()
    end

    test "returns proper callbacks based on node_id" do
      assert FiltersUtils.node_callbacks(%Phoenix.LiveComponent.CID{cid: 1}) ==
               CallbacksUtils.live_component_callbacks()

      assert FiltersUtils.node_callbacks(:c.pid(0, 123, 0)) ==
               CallbacksUtils.live_view_callbacks()
    end
  end

  test "calculate_selected_filters/2 returns the number of selected filters without min and max units" do
    current_filters = %{
      functions: %{
        "mount/3" => false
      },
      execution_time: %{
        exec_time_min: "10",
        exec_time_max: "",
        min_unit: "ms",
        max_unit: "ms"
      }
    }

    default_filters = %{
      functions: %{
        "mount/3" => true
      },
      execution_time: %{
        exec_time_min: "",
        exec_time_max: "",
        min_unit: "ms",
        max_unit: "ms"
      }
    }

    assert FiltersUtils.calculate_selected_filters(default_filters, current_filters) == 2
  end
end
