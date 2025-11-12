defmodule LiveDebugger.API.System.Module do
  @moduledoc """
  This module provides wrappers for system functions that queries modules in the current application.
  """

  @callback all() :: [{charlist(), charlist(), boolean()}]
  @callback loaded?(module :: module()) :: boolean()
  @callback behaviours(module :: module()) :: [module()]
  @callback has_component?(module :: module()) :: boolean()

  @doc """
  Wrapper for `:code.all_available/0`.
  Returns a list of tuples {Module, Filename, Loaded} for all available modules.
  """
  @spec all() :: [{charlist(), charlist(), boolean()}]
  def all(), do: impl().all()

  @doc """
  Wrapper for Code.ensure_loaded?/1 that returns if a module is loaded.
  """
  @spec loaded?(module :: module()) :: boolean()
  def loaded?(module), do: impl().loaded?(module)

  @doc """
  Returns list of behaviours implemented by the given module.
  """
  @spec behaviours(module :: module()) :: [module()]
  def behaviours(module), do: impl().behaviours(module)

  @doc """
  Returns list of functions that are generating function components.
  """
  @spec get_component_functions_from_module(module :: module()) :: boolean()
  def get_component_functions_from_module(module),
    do: impl().get_component_functions_from_module(module)

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_module,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.API.System.Module

    @impl true
    def all() do
      :code.all_available()
    end

    @impl true
    def loaded?(module) do
      Code.ensure_loaded?(module) and function_exported?(module, :module_info, 1)
    end

    @impl true
    def behaviours(module) do
      module.module_info(:attributes)[:behaviour] || []
    rescue
      # There is a chance that the module has been purged after we checked if it was loaded
      # check https://github.com/software-mansion/live-debugger/issues/730
      # It applies to compiler modules that does not have behaviours
      # It is safe to return empty list in this case
      UndefinedFunctionError -> []
    end

    def has_component?(Phoenix.Component) do
      false
    end

    @impl true
    def get_component_functions_from_module(module) do
      exports = module.module_info(:exports)

      has_component =
        Enum.any?(exports, &(&1 == {:__components__, 0})) and
          Enum.any?(exports, &(&1 == {:__phoenix_component_verify__, 1}))

      if has_component do
        one_arity_funs =
          exports
          |> Enum.filter(fn
            {name, 1}
            when name not in [
                   :module_info,
                   :__info__,
                   :__components__,
                   :__phoenix_verify_routes__,
                   :__phoenix_component_verify__
                 ] ->
              true

            _ ->
              false
          end)

        filter_funs_returning_lv_rendered(module, one_arity_funs, dummy_assigns())
      else
        []
      end
    end

    def dummy_assigns(), do: %{test: true, __changed__: %{}}

    defp filter_funs_returning_lv_rendered(module, one_arity_funs, assigns, timeout \\ 5) do
      one_arity_funs
      |> Enum.map(fn {name, 1} ->
        task =
          Task.async(fn ->
            try do
              result = apply(module, name, [assigns])

              case result do
                %Phoenix.LiveView.Rendered{} -> {:ok, {name, result}}
                _ -> :not_a_component
              end
            rescue
              e -> {:error, e}
            catch
              kind, reason -> {:caught, {kind, reason}}
            end
          end)

        case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
          {:ok, {:ok, {name, rendered}}} -> {:keep, {name, rendered}}
          _ -> :discard
        end
      end)
      |> Enum.filter_map(
        fn
          {:keep, _} -> true
          _ -> false
        end,
        fn
          {:keep, {name, rendered}} -> {module, name, 1}
        end
      )
    end
  end
end
