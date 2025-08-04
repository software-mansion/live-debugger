defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Utils.FiltersTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.App.Debugger.CallbackTracing.Utils.Filters, as: FiltersUtils
  alias LiveDebuggerRefactor.Utils.Callbacks, as: UtilsCallbacks

  describe "node_callbacks/1" do
    test "returns all callbacks when node_id is nil" do
      assert FiltersUtils.node_callbacks(nil) == UtilsCallbacks.all_callbacks()
    end

    test "returns proper callbacks based on node_id" do
      assert FiltersUtils.node_callbacks(%Phoenix.LiveComponent.CID{cid: 1}) ==
               UtilsCallbacks.live_component_callbacks()

      assert FiltersUtils.node_callbacks(:c.pid(0, 123, 0)) ==
               UtilsCallbacks.live_view_callbacks()
    end
  end

  test "parse_callback/1 works properly" do
    assert FiltersUtils.parse_callback({:mount, 3}) == "mount/3"
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

    assert FiltersUtils.group_changed?(params, filters, :functions)
    refute FiltersUtils.group_changed?(params, filters, :execution_time)
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

    assert FiltersUtils.filters_changed?(params, filters)
  end

  describe "validate_execution_time_params/1" do
    test "returns :ok if execution time params are valid" do
      assert FiltersUtils.validate_execution_time_params(%{
               "exec_time_min" => "10",
               "exec_time_max" => "20",
               "min_unit" => "ms",
               "max_unit" => "ms"
             }) == :ok
    end

    test "returns error if values are not integers" do
      assert {:error, errors} =
               FiltersUtils.validate_execution_time_params(%{
                 "exec_time_min" => "10",
                 "exec_time_max" => "20.5",
                 "min_unit" => "ms",
                 "max_unit" => "ms"
               })

      assert Keyword.equal?(errors,
               exec_time_max: "must be an integer"
             )

      assert {:error, errors} =
               FiltersUtils.validate_execution_time_params(%{
                 "exec_time_min" => "10.5",
                 "exec_time_max" => "20",
                 "min_unit" => "ms",
                 "max_unit" => "ms"
               })

      assert Keyword.equal?(errors,
               exec_time_min: "must be an integer"
             )

      assert {:error, errors} =
               FiltersUtils.validate_execution_time_params(%{
                 "exec_time_min" => "10.5",
                 "exec_time_max" => "20.5",
                 "min_unit" => "ms",
                 "max_unit" => "ms"
               })

      assert Keyword.equal?(errors,
               exec_time_min: "must be an integer",
               exec_time_max: "must be an integer"
             )
    end

    test "returns errors if min is greater than max" do
      assert {:error, errors} =
               FiltersUtils.validate_execution_time_params(%{
                 "exec_time_min" => "20",
                 "exec_time_max" => "10",
                 "min_unit" => "ms",
                 "max_unit" => "ms"
               })

      assert Keyword.equal?(errors,
               exec_time_min: "min must be less than max",
               exec_time_max: "max must be greater than min"
             )
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
