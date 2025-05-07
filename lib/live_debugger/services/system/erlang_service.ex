defmodule LiveDebugger.Services.System.ErlangService do
  @moduledoc """
  This module provides wrappers for erlang system functions that queries processes in the current application.
  """
  @callback process_info(binary(), atom()) :: {:ok, non_neg_integer()} | :error
  @callback garbage_collect(binary()) :: true

  @doc """
  Wrapper for `:erlang.process_info/2` that returns information on the process.
  Note our implementation only includes the call for :memory
  """
  @spec process_info(binary(), atom()) :: {:ok, non_neg_integer()} | :error
  def process_info(pid, type), do: impl().process_info(pid, type)

  @doc """
  Wrapper for `:erlang.garbage_collect/1` that garbage collects the pid.
  """
  @spec garbage_collect(binary()) :: true
  def garbage_collect(pid), do: impl().garbage_collect(pid)

  defp impl() do
    Application.get_env(
      :live_debugger,
      :erlang_service,
      LiveDebugger.Services.System.ErlangService.Impl
    )
  end
end

defmodule LiveDebugger.Services.System.ErlangService.Impl do
  @moduledoc false
  @behaviour LiveDebugger.Services.System.ErlangService

  @impl true
  def process_info(pid, :memory) do
    case :erlang.process_info(pid, :memory) do
      {:memory, bytes} -> {:ok, bytes}
      _ -> :error
    end
  end

  @impl true
  def process_info(_pid, _type), do: :error

  @impl true
  def garbage_collect(pid) do
    :erlang.garbage_collect(pid)
  end
end
