defmodule LiveDebugger.Services.ModuleDiscovery do
  @live_view_behaviour Phoenix.LiveView
  @live_component_behaviour Phoenix.LiveComponent

  @type live_modules() :: %{live_views: [module()], live_components: [module()]}

  @spec find_live_modules() :: live_modules()
  def find_live_modules() do
    loaded_modules = :code.all_loaded()

    %{
      live_views: find_modules_by_behaviour(loaded_modules, @live_view_behaviour),
      live_components: find_modules_by_behaviour(loaded_modules, @live_component_behaviour)
    }
  end

  defp find_modules_by_behaviour(loaded_modules, behaviour) do
    loaded_modules
    |> Enum.map(fn {module, _} -> module end)
    |> Enum.reject(&debugger?/1)
    |> Enum.filter(&loaded?/1)
    |> Enum.filter(&behaviour?(&1, behaviour))
  end

  defp loaded?(module), do: Code.ensure_loaded?(module)

  defp behaviour?(module, behaviour_to_find) do
    module_behaviours = module.module_info(:attributes)[:behaviour] || []
    Enum.member?(module_behaviours, behaviour_to_find)
  end

  defp debugger?(module) do
    module
    |> Atom.to_string()
    |> String.starts_with?("LiveDebugger.")
  end
end
