defmodule LiveDebugger.Services.ModuleDiscoveryService do
  @moduledoc """
  This module provides functions to discover LiveViews and LiveComponents in the current application.
  """

  alias LiveDebugger.Services.System.ModuleService

  @live_view_behaviour Phoenix.LiveView
  @live_component_behaviour Phoenix.LiveComponent

  @spec all_modules() :: [module()]
  def all_modules() do
    ModuleService.all()
    |> Enum.map(fn {module_charlist, _, _} ->
      module_charlist |> to_string |> String.to_atom()
    end)
  end

  @doc """
  Accepts a list of all modules from ModuleService.all/0
  Returns a list of loaded LiveView modules.
  """

  @spec live_view_modules(modules :: [module()]) :: [module()]
  def live_view_modules(modules) do
    find_modules_by_behaviour(modules, @live_view_behaviour)
  end

  @doc """
  Accepts a list of all modules from ModuleService.all/0
  Returns a list of loaded LiveComponent modules.

  ## Examples
  iex> services = LiveDebugger.Services.ModuleService.all()
  [{MyAppWeb.LiveComponent, 'lib/my_app_web/live_component.ex'}, ...]

  iex> LiveDebugger.Services.ModuleDiscoveryService.live_view_modules(services)
  [MyAppWeb.LiveComponent, ...]
  """
  @spec live_component_modules(modules :: [module()]) :: [module()]
  def live_component_modules(modules) do
    find_modules_by_behaviour(modules, @live_component_behaviour)
  end

  defp find_modules_by_behaviour(modules, behaviour) do
    modules
    |> Enum.filter(&ModuleService.loaded?/1)
    |> Enum.reject(&debugger?/1)
    |> Enum.filter(&behaviour?(&1, behaviour))
  end

  defp behaviour?(module, behaviour_to_find) do
    module_behaviours = ModuleService.behaviours(module)
    Enum.member?(module_behaviours, behaviour_to_find)
  end

  defp debugger?(module) do
    stringified_module = Atom.to_string(module)

    String.starts_with?(stringified_module, [
      "Elixir.LiveDebugger.",
      "Elixir.LiveDebuggerWeb.",
      "LiveDebugger.",
      "LiveDebuggerWeb."
    ])
  end
end
