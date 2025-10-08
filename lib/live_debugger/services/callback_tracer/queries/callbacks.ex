defmodule LiveDebugger.Services.CallbackTracer.Queries.Callbacks do
  @moduledoc """
  Queries the callbacks of the traced modules.
  """

  alias LiveDebugger.API.System.Module, as: ModuleAPI
  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks
  alias LiveDebugger.Utils.Modules, as: UtilsModules

  @doc """
  Returns a list of all callbacks of the traced modules.
  """
  @spec all_callbacks() :: [module()]
  def all_callbacks() do
    all_modules =
      ModuleAPI.all()
      |> Enum.map(fn {module_charlist, _, _} ->
        module_charlist |> to_string |> String.to_atom()
      end)
      |> Enum.filter(&ModuleAPI.loaded?/1)
      |> Enum.reject(&UtilsModules.debugger_module?/1)

    live_view_callbacks = UtilsCallbacks.live_view_callbacks()

    live_view_callbacks_to_trace =
      all_modules
      |> Enum.filter(&live_behaviour?(&1, Phoenix.LiveView))
      |> Enum.flat_map(fn module ->
        live_view_callbacks
        |> Enum.map(fn {callback, arity} -> {module, callback, arity} end)
      end)

    live_component_callbacks = UtilsCallbacks.live_component_callbacks()

    live_component_callbacks_to_trace =
      all_modules
      |> Enum.filter(&live_behaviour?(&1, Phoenix.LiveComponent))
      |> Enum.flat_map(fn module ->
        live_component_callbacks
        |> Enum.map(fn {callback, arity} -> {module, callback, arity} end)
      end)

    all_deps_modules =
      ModuleAPI.all()
      |> Enum.map(fn {module_charlist, _, _} ->
        module_charlist |> to_string |> String.to_atom()
      end)

    live_view_callbacks_to_trace ++ live_component_callbacks_to_trace
  end

  def all_component_functions() do
    all_modules =
      ModuleAPI.all()
      |> Enum.map(fn {module_charlist, _, _} ->
        module_charlist |> to_string |> String.to_atom()
      end)
      |> Enum.filter(&ModuleAPI.loaded?/1)
      |> Enum.reject(&UtilsModules.debugger_module?/1)

    component_functions =
      all_modules
      |> Enum.reject(&live_behaviour?(&1, Phoenix.LiveView))
      |> Enum.reject(&live_behaviour?(&1, Phoenix.LiveComponent))
      |> Enum.flat_map(&ModuleAPI.get_component_functions_from_module/1)

    # dbg(component_modules)

    component_functions
  end

  defp live_behaviour?(module, behaviour) do
    module |> ModuleAPI.behaviours() |> Enum.any?(&(&1 == behaviour))
  end
end
