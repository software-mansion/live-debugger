defmodule LiveDebugger.Services.CallbackTracer.Actions.DiffTrace do
  @moduledoc """
  This module provides actions for LiveView diffs.
  """

  alias LiveDebugger.Structs.Trace.DiffTrace
  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.DiffTraceCreated
  alias LiveDebugger.API.TracesStorage

  @doc """
  Creates a non-empty diff from raw diff trace. If diff is empty, returns nil.
  """
  @spec maybe_create_diff(non_neg_integer(), pid(), non_neg_integer(), iodata()) ::
          {:ok, DiffTrace.t()} | {:error, term()}
  def maybe_create_diff(n, pid, timestamp, iodata) do
    with body_binary <- IO.iodata_to_binary(iodata),
         {:ok, message_json} <- Jason.decode(body_binary),
         diff <- get_diff(message_json),
         {:ok, diff_size} <- get_diff_size(diff) do
      {:ok, DiffTrace.new(n, diff, pid, timestamp, diff_size)}
    end
  end

  @spec persist_trace(DiffTrace.t()) :: {:ok, reference()} | {:error, term()}
  def persist_trace(%DiffTrace{pid: pid} = trace) do
    with ref when is_reference(ref) <- TracesStorage.get_table(pid),
         true <- TracesStorage.insert!(ref, trace) do
      {:ok, ref}
    else
      _ ->
        {:error, "Could not persist trace"}
    end
  end

  @spec publish_diff(DiffTrace.t(), reference() | nil) :: :ok | {:error, term()}
  def publish_diff(%DiffTrace{pid: pid} = diff_trace, ref) do
    event = %DiffTraceCreated{trace_id: diff_trace.id, ets_ref: ref, pid: pid}
    Bus.broadcast_trace!(event, pid)
  rescue
    err ->
      {:error, err}
  end

  defp get_diff([_, _, _, "diff", payload]), do: payload
  defp get_diff([_, _, _, _type, %{"response" => response}]), do: response
  defp get_diff(_), do: %{}

  defp get_diff_size(diff) do
    case Jason.encode(diff) do
      {:ok, diff_binary} -> {:ok, byte_size(diff_binary)}
      {:error, _} -> {:error, "Could not encode diff"}
    end
  end
end
