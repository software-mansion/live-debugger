defmodule LiveDebuggerRefactor.Services.GarbageCollector.Queries.GarbageCollectingTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.Services.GarbageCollector.Queries.GarbageCollecting,
    as: GarbageCollectingQueries

  describe "max_table_size/1" do
    @megabyte_unit 1_048_576

    test "returns the correct size for watched tables" do
      Application.put_env(:live_debugger, :approx_table_max_size, 20)

      assert 20 * @megabyte_unit == GarbageCollectingQueries.max_table_size(:watched)
    end

    test "returns the correct size for non watched tables" do
      Application.put_env(:live_debugger, :approx_table_max_size, 20)

      assert 2 * @megabyte_unit == GarbageCollectingQueries.max_table_size(:non_watched)
    end
  end
end
