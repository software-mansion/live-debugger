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

  describe "default_filters/1" do
    test "returns proper filters when node_id is nil" do
      assert FiltersHelpers.default_filters(nil) == %{
               functions: %{
                 "mount/3" => true,
                 "mount/1" => true,
                 "handle_params/3" => true,
                 "update/2" => true,
                 "update_many/1" => true,
                 "render/1" => true,
                 "handle_event/3" => true,
                 "handle_async/3" => true,
                 "handle_info/2" => true,
                 "handle_call/3" => true,
                 "handle_cast/2" => true,
                 "terminate/2" => true
               },
               execution_time: %{
                 "exec_time_max" => "",
                 "exec_time_min" => "",
                 "min_unit" => "µs",
                 "max_unit" => "µs"
               }
             }
    end

    test "returns proper filters when node_id is CID" do
      assert FiltersHelpers.default_filters(%Phoenix.LiveComponent.CID{cid: 1}) == %{
               functions: %{
                 "mount/1" => true,
                 "update/2" => true,
                 "update_many/1" => true,
                 "render/1" => true,
                 "handle_event/3" => true,
                 "handle_async/3" => true
               },
               execution_time: %{
                 "exec_time_max" => "",
                 "exec_time_min" => "",
                 "min_unit" => "µs",
                 "max_unit" => "µs"
               }
             }
    end

    test "returns proper filters when node_id is PID" do
      assert FiltersHelpers.default_filters(:c.pid(0, 123, 0)) == %{
               functions: %{
                 "mount/3" => true,
                 "handle_params/3" => true,
                 "render/1" => true,
                 "handle_event/3" => true,
                 "handle_async/3" => true,
                 "handle_info/2" => true,
                 "handle_call/3" => true,
                 "handle_cast/2" => true,
                 "terminate/2" => true
               },
               execution_time: %{
                 "exec_time_max" => "",
                 "exec_time_min" => "",
                 "min_unit" => "µs",
                 "max_unit" => "µs"
               }
             }
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

  describe "validate_execution_time_params/1" do
    test "returns :ok if execution time params are valid" do
      assert FiltersHelpers.validate_execution_time_params(%{
               "exec_time_min" => "10",
               "exec_time_max" => "20",
               "min_unit" => "ms",
               "max_unit" => "ms"
             }) == :ok
    end

    test "returns error if values are not integers" do
      assert {:error, errors} =
               FiltersHelpers.validate_execution_time_params(%{
                 "exec_time_min" => "10",
                 "exec_time_max" => "20.5",
                 "min_unit" => "ms",
                 "max_unit" => "ms"
               })

      assert Keyword.equal?(errors,
               exec_time_max: "must be an integer"
             )

      assert {:error, errors} =
               FiltersHelpers.validate_execution_time_params(%{
                 "exec_time_min" => "10.5",
                 "exec_time_max" => "20",
                 "min_unit" => "ms",
                 "max_unit" => "ms"
               })

      assert Keyword.equal?(errors,
               exec_time_min: "must be an integer"
             )

      assert {:error, errors} =
               FiltersHelpers.validate_execution_time_params(%{
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
               FiltersHelpers.validate_execution_time_params(%{
                 "exec_time_min" => "20",
                 "exec_time_max" => "10",
                 "min_unit" => "ms",
                 "max_unit" => "ms"
               })

      assert Keyword.equal?(errors, exec_time_min: "min must be less than max")
    end
  end

  test "count_selected_filters/2 returns the number of selected filters without min and max units" do
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

    assert FiltersHelpers.count_selected_filters(default_filters, current_filters) == 2
  end

  test "get_active_functions/1 returns currently active functions from filters" do
    filters = %{
      functions: %{
        "mount/3" => false,
        "render/1" => true,
        "handle_info/2" => true
      },
      execution_time: %{
        "exec_time_min" => "10",
        "exec_time_max" => "",
        "min_unit" => "ms",
        "max_unit" => "ms"
      }
    }

    assert functions = FiltersHelpers.get_active_functions(filters)
    assert 2 == length(functions)
    assert "render/1" in functions
    assert "handle_info/2" in functions
  end

  describe "get_execution_times/1" do
    test "returns currently active execution time limits from filters" do
      filters = %{
        functions: %{
          "mount/3" => false
        },
        execution_time: %{
          "exec_time_min" => "14",
          "exec_time_max" => "2",
          "min_unit" => "ms",
          "max_unit" => "s"
        }
      }

      assert %{
               "exec_time_min" => 14_000,
               "exec_time_max" => 2_000_000
             } =
               FiltersHelpers.get_execution_times(filters)
    end

    test "returns only non empty execution time limits from filters" do
      filters = %{
        functions: %{
          "mount/3" => false
        },
        execution_time: %{
          "exec_time_min" => "140",
          "exec_time_max" => "",
          "min_unit" => "µs",
          "max_unit" => "s"
        }
      }

      assert %{"exec_time_min" => 140} = FiltersHelpers.get_execution_times(filters)
    end
  end
end
