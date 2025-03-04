defmodule LiveDebugger.Services.System.ProcessService do
  @moduledoc """
  This module provides wrappers for system functions that queries processes in the current application.
  """
  @callback initial_call(pid :: pid()) :: mfa() | nil
  @callback state(pid :: pid()) :: {:ok, term()} | {:error, term()}
  @callback list() :: [pid()]

  @doc """
  Wrapper for `Process.info/2` with some additional logic that returns the initial call of the process.
  """
  @spec initial_call(pid :: pid()) :: mfa() | nil
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
      :process_service,
      LiveDebugger.Services.System.ProcessService.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.Services.System.ProcessService

    @impl true
    def initial_call(pid) do
      pid
      |> Process.info([:dictionary])
      |> case do
        nil -> nil
        result -> get_in(result, [:dictionary, :"$initial_call"])
      end
    end

    @impl true
    def state(pid) do
      if Process.alive?(pid) do
        {:ok, :sys.get_state(pid)}
      else
        {:error, :not_alive}
      end
    rescue
      _ -> {:error, "Could not get state from pid: #{inspect(pid)}"}
    end

    @impl true
    def list(), do: Process.list()
  end
end
