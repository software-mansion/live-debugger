defmodule LiveDebugger.Utils.Formatters do
  @moduledoc """
  This module provides functions to format data to be displayed in the UI.
  """
  def module_short_name(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end
end
