defmodule LiveDebugger.API.System.Process do
  @moduledoc """
  This module provides wrappers for system functions that queries processes in the current application.

  ## Deprecated

  This module is deprecated and will be removed in a future version.
  It is only used to support Phoenix LiveView versions prior to 1.1.0.
  Once the minimum LiveView version is bumped to 1.1.0, this module will be deleted.

  It is discouraged to use it directly.
  It will be entirely moved to `LiveDebugger.API.LiveViewDebug` in the future.

  https://github.com/software-mansion/live-debugger/issues/577
  """
  @callback initial_call(pid :: pid()) :: {:ok, mfa()} | {:error, term()}
  @callback state(pid :: pid()) :: {:ok, term()} | {:error, term()}
  @callback list() :: [pid()]

  @doc deprecated: "This module is deprecated and will be removed in a future version"
  @spec initial_call(pid :: pid()) :: {:ok, mfa()} | {:error, term()}
  def initial_call(pid), do: impl().initial_call(pid)

  @doc deprecated: "This module is deprecated and will be removed in a future version"
  @spec state(pid :: pid()) :: {:ok, term()} | {:error, term()}
  def state(pid), do: impl().state(pid)

  @doc deprecated: "This module is deprecated and will be removed in a future version"
  @spec list() :: [pid()]
  def list(), do: impl().list()

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_process,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.API.System.Process

    @impl true
    def initial_call(pid) do
      pid
      |> Process.info([:dictionary])
      |> case do
        nil ->
          {:error, :not_alive}

        result ->
          case get_in(result, [:dictionary, :"$initial_call"]) do
            nil -> {:error, :no_initial_call}
            initial_call -> {:ok, initial_call}
          end
      end
    end

    @impl true
    def state(pid) do
      try do
        if Process.alive?(pid) do
          {:ok, :sys.get_state(pid)}
        else
          {:error, :not_alive}
        end
      catch
        :exit, reason ->
          {:error, reason}
      end
    end

    @impl true
    def list(), do: Process.list()
  end
end
