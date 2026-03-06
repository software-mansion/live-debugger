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
  @spec all_callbacks() :: [mfa()]
  def all_callbacks() do
    all_modules = fetch_all_live_modules()

    build_callbacks_from_modules(all_modules)
  end

  @doc """
  Returns a list of all callbacks given a list of module atoms.
  More efficient when you already have the module list.

  When called with a single module atom, returns callbacks for that module only,
  or an error if the module is not a LiveView or LiveComponent.
  """
  @spec all_callbacks([module()]) :: [mfa()]
  def all_callbacks(modules) when is_list(modules) do
    build_callbacks_from_modules(modules)
  end

  @spec all_callbacks(module()) :: [mfa()] | {:error, term()}
  def all_callbacks(module) when is_atom(module) do
    case all_callbacks([module]) do
      [] -> {:error, "Module #{module} is not a LiveView or LiveComponent"}
      callbacks -> callbacks
    end
  end

  @doc """
  Returns a list of all live modules (LiveViews and LiveComponents) with their compiled paths.
  Returns a list of {module, path} tuples.
  """
  @spec all_live_modules_with_paths() :: [{module(), String.t()}]
  def all_live_modules_with_paths() do
    ModuleAPI.all()
    |> Enum.map(fn {module_charlist, compiled_path, _} ->
      {module_charlist |> to_string |> String.to_atom(), to_string(compiled_path)}
    end)
    |> Enum.filter(fn {module, _} -> ModuleAPI.loaded?(module) end)
    |> Enum.reject(fn {module, _} -> UtilsModules.debugger_module?(module) end)
    |> Enum.filter(fn {module, _} -> ModuleAPI.live_module?(module) end)
  end

  defp live_behaviour?(module, behaviour) do
    module |> ModuleAPI.behaviours() |> Enum.any?(&(&1 == behaviour))
  end

  defp fetch_all_live_modules() do
    all_live_modules_with_paths()
    |> Enum.map(fn {module, _path} -> module end)
  end

  defp build_callbacks_from_modules(modules) do
    live_view_callbacks = UtilsCallbacks.live_view_callbacks()
    live_component_callbacks = UtilsCallbacks.live_component_callbacks()

    live_view_callbacks_to_trace =
      modules
      |> Enum.filter(&live_behaviour?(&1, Phoenix.LiveView))
      |> Enum.flat_map(fn module ->
        live_view_callbacks
        |> Enum.map(fn {callback, arity} -> {module, callback, arity} end)
      end)

    live_component_callbacks_to_trace =
      modules
      |> Enum.filter(&live_behaviour?(&1, Phoenix.LiveComponent))
      |> Enum.flat_map(fn module ->
        live_component_callbacks
        |> Enum.map(fn {callback, arity} -> {module, callback, arity} end)
      end)

    live_view_callbacks_to_trace ++ live_component_callbacks_to_trace
  end
end
