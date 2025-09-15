defmodule LiveDebugger.Services.GarbageCollector.UtilsTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Services.GarbageCollector.Utils,
    as: GarbageCollectorUtils

  describe "max_table_size/1" do
    @megabyte_unit 1_048_576

    test "returns the correct size for watched tables" do
      assert 50 * @megabyte_unit == GarbageCollectorUtils.max_table_size(:watched)
    end

    test "returns the correct size for non watched tables" do
      assert 5 * @megabyte_unit == GarbageCollectorUtils.max_table_size(:non_watched)
    end
  end
end
