defmodule LiveDebugger.Services.LiveViewApi do
  @callback state_from_pid(pid :: pid()) :: {:ok, map()} | {:error, term()}

  def state_from_pid(pid), do: impl().state_from_pid(pid)

  defp impl(),
    do: Application.get_env(:live_debugger, :live_view_api, LiveDebugger.Services.LiveViewApiImpl)
end

defmodule LiveDebugger.Services.LiveViewApiImpl do
  @moduledoc """
  This module provides functions to work with the state of the LiveView process.
  """

  @behaviour LiveDebugger.Services.LiveViewApi

  @doc """
  Returns the state of the process with the given PID.
  """
  @impl true
  def state_from_pid(pid) when is_pid(pid) do
    try do
      {:ok, :sys.get_state(pid)}
    rescue
      _ -> {:error, "Could not get state from pid: #{inspect(pid)}"}
    end
  end
end
