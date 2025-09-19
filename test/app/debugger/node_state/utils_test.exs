defmodule App.Debugger.NodeState.UtilsTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.App.Debugger.NodeState.Utils, as: NodeStateUtils

  defmodule SampleStruct do
    defstruct [:field1, :field2]
  end

  test "diff_assigns/2 returns the correct diff between two maps" do
    old_assigns = %{
      a: 1,
      b: 2,
      c: %{
        :d => [1, 2, 3],
        32 => {:ok, %{result: "test"}}
      },
      e: %SampleStruct{field1: "value1", field2: "value2"},
      f: %{
        nested: %{
          key1: "val1"
        }
      },
      struct_as_key: %{
        %SampleStruct{} => nil,
        %SampleStruct{field1: 23} => nil
      }
    }

    new_assigns = %{
      a: 2,
      b: 2,
      c: %{
        :d => [1, 2, 3, 4],
        32 => {:ok, %{result: "test changed"}}
      },
      e: %SampleStruct{field1: "value1", field2: "other"},
      f: %{
        nested: %{
          key2: "val1"
        }
      },
      struct_as_key: %{
        %SampleStruct{} => "some value",
        %SampleStruct{field1: 1000} => nil
      }
    }

    expected_diff = %{
      a: true,
      c: %{
        :d => true,
        32 => true
      },
      e: %{
        field2: true
      },
      f: %{
        nested: %{
          key1: true,
          key2: true
        }
      },
      struct_as_key: %{
        %SampleStruct{} => true,
        %SampleStruct{field1: 23} => true,
        %SampleStruct{field1: 1000} => true
      }
    }

    assert NodeStateUtils.diff(old_assigns, new_assigns) == expected_diff
  end
end
