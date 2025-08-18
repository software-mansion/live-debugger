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

    live_view_callbacks_to_trace ++ live_component_callbacks_to_trace
  end

  defp live_behaviour?(module, behaviour) do
    module |> ModuleAPI.behaviours() |> Enum.any?(&(&1 == behaviour))
  end
end
