defmodule LiveDebugger.Services.GarbageCollector.Utils do
  @moduledoc """
  Utility functions for the GarbageCollector service.
  """

  @megabyte_unit 1_048_576
  @watched_table_size 50 * @megabyte_unit
  @non_watched_table_size 5 * @megabyte_unit

  # Ets tables might exceed the maximum size since these are approximate values (e.g. 10MB might have 20MB of data).
  @spec max_table_size(:watched | :non_watched) :: non_neg_integer()
  def max_table_size(:watched), do: @watched_table_size
  def max_table_size(:non_watched), do: @non_watched_table_size
end
