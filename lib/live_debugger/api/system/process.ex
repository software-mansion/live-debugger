defmodule LiveDebugger.API.System.Process do
  @moduledoc """
  This module provides wrappers for system functions that queries processes in the current application.

  It is discouraged to use it
  It will be entirely moved to `LiveDebugger.API.LiveViewDebug` in the future.

  https://github.com/software-mansion/live-debugger/issues/577
  """
  @callback initial_call(pid :: pid()) :: {:ok, mfa()} | {:error, term()}
  @callback state(pid :: pid()) :: {:ok, term()} | {:error, term()}
  @callback list() :: [pid()]

  @doc """
  Wrapper for `Process.info/2` with some additional logic that returns the initial call of the process.
  """
  @spec initial_call(pid :: pid()) :: {:ok, mfa()} | {:error, term()}
  def initial_call(pid), do: impl().initial_call(pid)

  @doc """
  Wrapper for `:sys.get_state/1` with additional error handling that returns the state of the process.
  """
  @spec state(pid :: pid()) :: {:ok, term()} | {:error, term()}
  def state(pid), do: impl().state(pid)

  @doc """
  Wrapper for `Process.list/0` that returns a list of pids.
  """
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
