defmodule LiveDebugger.Services.LiveViewDiscoveryService do
  @moduledoc """
  This module provides functions that discovers LiveView processes in the debugged application.
  """
  alias LiveDebugger.Services.System.ProcessService

  @doc """
  Returns pids of all LiveView processes in the debugged application.
  """
  @spec debugged_live_pids() :: [pid()]
  def debugged_live_pids() do
    live_pids()
    |> Enum.reject(fn {_, initial_call} -> debugger?(initial_call) end)
    |> Enum.map(&elem(&1, 0))
  end

  @doc """
  Returns pids of all LiveView processes in the LiveDebugger application
  """
  @spec debugger_live_pids() :: [pid()]
  def debugger_live_pids() do
    live_pids()
    |> Enum.filter(fn {_, initial_call} -> debugger?(initial_call) end)
    |> Enum.map(&elem(&1, 0))
  end

  @doc """
  Returns pid of the LiveView process associated the given `socket_id`.
  """
  @spec live_pid(socket_id :: binary()) :: {pid(), module()} | nil
  def live_pid(socket_id) do
    debugged_live_pids()
    |> Enum.map(fn pid -> {pid, ProcessService.state(pid)} end)
    |> Enum.find(fn
      {_, {:ok, %{socket: %{id: id}}}} -> id == socket_id
      {:error, _} -> false
    end)
    |> case do
      # TODO This is temporary to make fetching module easier for session dashboard
      {pid, {:ok, %{socket: %{view: module}}}} -> {pid, module}
      nil -> nil
    end
  end

  @doc """
  Finds potential successor PID based on module when websocket connection breaks and new one is created
  This is a common scenario when user recompiles code or refreshes the page
  """
  @spec find_successor_pid(module :: module()) :: [pid()]
  def find_successor_pid(module) do
    live_pids()
    |> Enum.filter(fn {_, initial_call} ->
      not debugger?(initial_call) and same_module(initial_call, module)
    end)
    |> Enum.map(&elem(&1, 0))
  end

  defp live_pids() do
    ProcessService.list()
    |> Enum.reject(&(&1 == self()))
    |> Enum.map(&{&1, ProcessService.initial_call(&1)})
    |> Enum.filter(fn {_, initial_call} -> liveview?(initial_call) end)
  end

  defp liveview?(initial_call) when initial_call not in [nil, {}] do
    elem(initial_call, 1) == :mount
  end

  defp liveview?(_), do: false

  defp debugger?(initial_call) when initial_call not in [nil, {}] do
    initial_call
    |> elem(0)
    |> Atom.to_string()
    |> String.starts_with?("Elixir.LiveDebugger.")
  end

  defp debugger?(_), do: false

  defp same_module(_, nil), do: true

  defp same_module({module, _, _}, current_module) do
    module == current_module
  end
end
