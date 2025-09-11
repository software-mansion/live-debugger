defmodule LiveDebugger.Services.GarbageCollector.Utils do
  @moduledoc """
  Utility functions for the GarbageCollector service.
  """

  @megabyte_unit 1_048_576
  @default_table_size 20

  # Ets tables might exceed the maximum size since these are approximate values (e.g. 10MB might have 20MB of data).
  @spec max_table_size(:watched | :non_watched) :: non_neg_integer()

  def max_table_size(type) when type in [:watched, :non_watched] do
    multiplier =
      case type do
        :watched -> 1
        :non_watched -> 0.1
      end

    @default_table_size
    |> Kernel.*(@megabyte_unit)
    |> Kernel.*(multiplier)
    |> round()
  end
end
