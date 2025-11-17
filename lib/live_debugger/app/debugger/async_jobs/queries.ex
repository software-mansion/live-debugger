defmodule LiveDebugger.App.Debugger.AsyncJobs.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.Debugger.AsyncJobs` context.
  """

  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.API.TracesStorage
  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.Structs.Trace.FunctionTrace
  alias Phoenix.LiveView.Socket
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.StartAsync
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.AsyncAssign

  @type cid() :: LiveDebugger.CommonTypes.cid()

  @spec fetch_async_jobs(pid(), cid() | pid()) :: {:ok, [AsyncJob.t()]} | {:error, term()}
  def fetch_async_jobs(pid, node_id) when is_pid(pid) do
    with {:ok, state} <- fetch_node_state(pid, node_id),
         live_async <- get_live_async(state) do
      {:ok, parse_live_async(live_async)}
    end
  end

  @spec fetch_async_jobs({reference(), integer()}) :: {:ok, [AsyncJob.t()]} | {:error, term()}
  def fetch_async_jobs({ets_ref, trace_id}) do
    with trace when not is_nil(trace) <- TracesStorage.get_by_id!(ets_ref, trace_id),
         live_async <- get_live_async(trace) do
      {:ok, parse_live_async(live_async)}
    else
      nil ->
        {:error, "Trace not found"}
    end
  end

  defp fetch_node_state(pid, node_id) when is_pid(node_id) do
    LiveViewDebug.liveview_state(pid)
  end

  defp fetch_node_state(pid, %Phoenix.LiveComponent.CID{cid: cid} = _node_id) do
    case LiveViewDebug.liveview_state(pid) do
      {:ok, %LvState{components: components}} ->
        state = Enum.find(components, fn component -> component.cid == cid end)
        {:ok, state}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_live_async(%LvState{socket: %{private: %{live_async: live_async}}}), do: live_async

  defp get_live_async(%FunctionTrace{
         return_value: {_, %Socket{private: %{live_async: live_async}}}
       }) do
    live_async
  end

  defp get_live_async(%{cid: _cid, private: %{live_async: live_async}}) do
    live_async
  end

  defp get_live_async(_), do: %{}

  defp parse_live_async(live_async) do
    live_async
    |> Enum.map(&parse_job/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_job({name, {ref, pid, :start}}) when is_atom(name) do
    StartAsync.new(pid, name, ref)
  end

  defp parse_job({keys, {ref, pid, :assign}}) when is_list(keys) do
    AsyncAssign.new(pid, keys, ref)
  end
end
