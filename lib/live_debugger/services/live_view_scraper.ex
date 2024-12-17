defmodule LiveDebugger.Services.LiveViewScraper do
  @callback channel_state_from_pid(pid :: pid()) :: {:ok, map()} | {:error, term()}
  @callback pid_by_socket_id(socket_id :: String.t()) :: pid() | nil
  @callback pids() :: [pid()]

  def channel_state_from_pid(pid), do: impl().channel_state_from_pid(pid)
  def pid_by_socket_id(socket_id), do: impl().pid_by_socket_id(socket_id)
  def pids(), do: impl().pids()

  defp impl() do
    Application.get_env(
      :live_debugger,
      :live_view_api,
      LiveDebugger.Services.LiveViewScraperImpl
    )
  end
end

defmodule LiveDebugger.Services.LiveViewScraperImpl do
  @moduledoc """
  This module provides functions to work with the state of the LiveView process.
  """

  @behaviour LiveDebugger.Services.LiveViewScraper

  @doc """
  Returns the state of the process with the given PID.
  """
  @impl true
  def channel_state_from_pid(pid) when is_pid(pid) do
    try do
      {:ok, :sys.get_state(pid)}
    rescue
      _ -> {:error, "Could not get state from pid: #{inspect(pid)}"}
    end
  end

  @impl true
  def pid_by_socket_id(socket_id) do
    pids()
    |> Enum.map(fn pid -> {pid, :sys.get_state(pid)} end)
    |> Enum.find(fn {_, %{socket: %{id: id}}} -> id == socket_id end)
    |> case do
      {pid, _} -> pid
      nil -> nil
    end
  end

  @impl true
  def pids() do
    Process.list()
    |> Enum.reject(&(&1 == self()))
    |> Enum.map(&{&1, process_initial_call(&1)})
    |> Enum.filter(fn {_, initial_call} -> liveview?(initial_call) end)
    |> Enum.reject(fn {_, initial_call} -> debugger?(initial_call) end)
    |> Enum.map(&elem(&1, 0))
  end

  defp process_initial_call(pid) do
    pid
    |> Process.info([:dictionary])
    |> hd()
    |> elem(1)
    |> Keyword.get(:"$initial_call", {})
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
