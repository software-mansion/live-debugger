defmodule LiveDebugger.App.Debugger.AsyncJobs.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.Debugger.AsyncJobs` context.
  """

  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.API.StatesStorage

  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.StartAsync
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.AsyncAssign

  @spec fetch_async_jobs(pid()) :: {:ok, [AsyncJob.t()]} | {:error, term()}
  def fetch_async_jobs(pid) do
    with {:ok, state} <- fetch_node_state(pid),
         live_async <- get_live_async(state) do
      jobs =
        live_async
        |> Enum.map(&parse_job/1)
        |> Enum.reject(&is_nil/1)

      {:ok, jobs}
    end
  end

  defp parse_job({name, {ref, pid, :start}}) when is_atom(name) do
    StartAsync.new(pid, name, ref)
  end

  defp parse_job({keys, {ref, pid, :assign}}) when is_list(keys) do
    AsyncAssign.new(pid, keys, ref)
  end

  defp fetch_node_state(pid) do
    case StatesStorage.get!(pid) do
      nil -> LiveViewDebug.liveview_state(pid)
      state -> {:ok, state}
    end
  end

  defp get_live_async(%LvState{socket: %{private: %{live_async: live_async}}}), do: live_async
  defp get_live_async(_), do: %{}
end
