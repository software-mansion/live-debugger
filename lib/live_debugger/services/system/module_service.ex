defmodule LiveDebugger.Services.System.ModuleService do
  @moduledoc """
  This module provides wrappers for system functions that queries modules in the current application.
  """

  @callback all() :: [{charlist(), charlist(), boolean()}]
  @callback loaded?(module :: module()) :: boolean()
  @callback behaviours(module :: module()) :: [module()]

  @doc """
  Wrapper for `:code.all_loaded/0` that returns a list of loaded modules.
  """
  @spec all() :: [{module(), charlist()}]
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

  defp impl() do
    Application.get_env(
      :live_debugger,
      :module_service,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.Services.System.ModuleService

    @impl true
    def all() do
      :code.all_available()
    end

    @impl true
    def loaded?(module) do
      Code.ensure_loaded?(module)
    end

    @impl true
    def behaviours(module) do
      module.module_info(:attributes)[:behaviour] || []
    end
  end
end
