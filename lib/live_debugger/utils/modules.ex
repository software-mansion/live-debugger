defmodule LiveDebugger.Utils.Modules do
  @moduledoc """
  Utility functions for working with modules.
  """

  @doc """
  Checks if a module is a LiveDebugger module.
  """
  @spec debugger_module?(module()) :: boolean()
  def debugger_module?(module) do
    stringified_module = Atom.to_string(module)

    String.starts_with?(stringified_module, [
      "Elixir.LiveDebugger.",
      "LiveDebugger."
    ])
  end
end
