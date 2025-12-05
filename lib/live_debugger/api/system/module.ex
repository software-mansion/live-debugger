defmodule LiveDebugger.API.System.Module do
  @moduledoc """
  This module provides wrappers for system functions that queries modules in the current application.
  """

  @callback all() :: [{charlist(), charlist(), boolean()}]
  @callback loaded?(module :: module()) :: boolean()
  @callback behaviours(module :: module()) :: [module()]
  @callback live_module?(module :: module()) :: boolean()

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
  Returns true if the module implements Phoenix.LiveView or Phoenix.LiveComponent behaviour.
  """
  @spec live_module?(module :: module()) :: boolean()
  def live_module?(module), do: impl().live_module?(module)

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

    @impl true
    def live_module?(module) do
      module
      |> behaviours()
      |> Enum.any?(&(&1 == Phoenix.LiveView || &1 == Phoenix.LiveComponent))
    end
  end
end
