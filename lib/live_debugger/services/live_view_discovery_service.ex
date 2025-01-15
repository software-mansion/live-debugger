defmodule LiveDebugger.Services.LiveViewDiscoveryService do
  @moduledoc """
  This module provides functions that discovers LiveView processes in the debugged application.
  """
  alias LiveDebugger.Services.System.ProcessService

  @doc """
  Returns pids of all LiveView processes in the debugged application.
  """
  @spec live_pids() :: [pid()]
  def live_pids() do
    ProcessService.list()
    |> Enum.reject(&(&1 == self()))
    |> Enum.map(&{&1, ProcessService.initial_call(&1)})
    |> Enum.filter(fn {_, initial_call} -> liveview?(initial_call) end)
    |> Enum.reject(fn {_, initial_call} -> debugger?(initial_call) end)
    |> Enum.map(&elem(&1, 0))
  end

  @doc """
  Returns pid of the LiveView process associated the given `socket_id`.
  """
  @spec live_pid(socket_id :: binary()) :: pid() | nil
  def live_pid(socket_id) do
    live_pids()
    |> Enum.map(fn pid -> {pid, ProcessService.state(pid)} end)
    |> Enum.find(fn
      {_, {:ok, %{socket: %{id: id}}}} -> id == socket_id
      {:error, _} -> false
    end)
    |> case do
      {pid, _} -> pid
      nil -> nil
    end
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
end
