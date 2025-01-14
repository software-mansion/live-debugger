defmodule LiveDebugger.Services.ModuleDiscoveryService do
  @moduledoc """
  This module provides functions to discover LiveViews and LiveComponents in the current application.
  """

  @live_view_behaviour Phoenix.LiveView
  @live_component_behaviour Phoenix.LiveComponent

  @doc """
  Wrapper for `:code.all_loaded/0` that returns a list of loaded modules.
  """
  @spec load_modules() :: [{module(), charlist()}]
  def load_modules(), do: :code.all_loaded()

  @doc """
  Returns a list of loaded LiveView modules.
  """
  @spec live_view_modules(loaded_modules :: [{module(), charlist()}]) :: [module()]
  def live_view_modules(loaded_modules) do
    find_modules_by_behaviour(loaded_modules, @live_view_behaviour)
  end

  @doc """
  Returns a list of loaded LiveComponent modules.
  """
  @spec live_component_modules(loaded_modules :: [{module(), charlist()}]) :: [module()]
  def live_component_modules(loaded_modules) do
    find_modules_by_behaviour(loaded_modules, @live_component_behaviour)
  end

  defp find_modules_by_behaviour(loaded_modules, behaviour) do
    loaded_modules
    |> Enum.map(fn {module, _} -> module end)
    |> Enum.filter(&loaded?/1)
    |> Enum.reject(&debugger?/1)
    |> Enum.filter(&behaviour?(&1, behaviour))
  end

  defp loaded?(module), do: Code.ensure_loaded?(module)

  defp behaviour?(module, behaviour_to_find) do
    module_behaviours = module.module_info(:attributes)[:behaviour] || []
    Enum.member?(module_behaviours, behaviour_to_find)
  end

  defp debugger?(module) do
    stringified_module = Atom.to_string(module)

    String.starts_with?(stringified_module, "LiveDebugger.") or
      String.starts_with?(stringified_module, "Elixir.LiveDebugger.")
  end
end
