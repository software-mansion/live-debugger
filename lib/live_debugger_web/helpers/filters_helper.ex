defmodule LiveDebuggerWeb.Helpers.FiltersHelper do
  @moduledoc """
  This module provides a helper for traces filters.
  """

  def calculate_selected_filters(current_filters, default_filters) do
    dbg(current_filters)
    dbg(default_filters)

    current_filters
    |> Map.keys()
    |> Enum.count(fn key -> current_filters[key] != default_filters[key] end)
  end
end
